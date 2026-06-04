import Foundation
import OSLog

struct ReadingCompletionResult {

    let upload: ReadingUpload
    let dailyLog: DailyLog
    let profile: Profile
    let xpAwarded: Int
    let levelState: XPSystem.LevelState
    let advancedChallenge: Challenge?

}

@MainActor
final class ReadingEngine {

    private static let readingXP = 10

    private let readingService: ReadingService
    private let dailyLogService: DailyLogService
    private let xpService: XPService
    private let challengeEngine: ChallengeEngine
    private let skillTreeService: SkillTreeService
    private let analyticsService: AnalyticsService
    private weak var gameState: GameState?

    init(
        readingService: ReadingService = ReadingService(),
        dailyLogService: DailyLogService = DailyLogService(),
        xpService: XPService = XPService(),
        challengeEngine: ChallengeEngine? = nil,
        skillTreeService: SkillTreeService = SkillTreeService(),
        analyticsService: AnalyticsService = AnalyticsService()
    ) {
        self.readingService = readingService
        self.dailyLogService = dailyLogService
        self.xpService = xpService
        self.challengeEngine = challengeEngine ?? ChallengeEngine()
        self.skillTreeService = skillTreeService
        self.analyticsService = analyticsService
    }

    func configure(gameState: GameState) {
        self.gameState = gameState
    }

    func completeReading(
        imageData: Data,
        date: Date = Date()
    ) async -> ReadingCompletionResult? {

        guard let gameState, !gameState.profile.isPlaceholder else {
            RNFLogger.sync.info("operation=complete_reading result=skipped reason=missing_or_placeholder_state")
            return nil
        }

        do {
            let existingLog = try await readingService.dailyLogForReading(
                userId: gameState.profile.id,
                date: date
            )

            guard !existingLog.reading_completed else {
                RNFLogger.sync.info("operation=complete_reading result=skipped reason=duplicate")
                return nil
            }

            let upload = try await readingService.uploadReadingProof(
                imageData: imageData,
                userId: gameState.profile.id,
                date: date
            )

            var completedLog = try await readingService.dailyLogForReading(
                userId: gameState.profile.id,
                date: date
            )

            var updatedProfile = gameState.profile
            let activePerks = (try? await skillTreeService.activePerks(for: updatedProfile)) ?? .empty
            let awardedXP = PerkSystem.modifiedXPReward(
                baseXP: Self.readingXP,
                activePerks: activePerks,
                currentDailyXP: completedLog.xp_earned
            )
            let levelState = xpService.awardXP(
                currentTotal: updatedProfile.xp_total,
                gainedXP: awardedXP
            )

            updatedProfile.xp_total = levelState.totalXP
            updatedProfile.level = levelState.level
            completedLog.xp_earned += awardedXP

            let dailyLogSaveResult = await dailyLogService.saveDailyLog(completedLog)
            let profileSaveResult = await dailyLogService.saveProfile(updatedProfile)

            guard dailyLogSaveResult.savedRemotely, profileSaveResult.savedRemotely else {
                RNFLogger.sync.error("operation=complete_reading result=failure step=save_state daily_log_state=\(String(describing: dailyLogSaveResult.saveState), privacy: .public) profile_state=\(String(describing: profileSaveResult.saveState), privacy: .public)")
                return nil
            }

            gameState.apply(
                profile: updatedProfile,
                levelState: levelState,
                titles: gameState.titles,
                quests: gameState.quests,
                dailyGoal: gameState.dailyGoal,
                dailyCompleted: gameState.dailyCompleted,
                completedHabitIDs: gameState.completedHabitIDs,
                dailyLog: completedLog
            )

            let advancedChallenge = await challengeEngine.advanceIfDayComplete(
                userId: updatedProfile.id,
                date: date
            )

            await analyticsService.trackEvent(
                .readingCompleted,
                properties: [
                    "user_id": updatedProfile.id.uuidString,
                    "proof_uploaded": "true",
                    "xp_awarded": "\(awardedXP)",
                    "timestamp": Self.analyticsTimestamp(for: date)
                ]
            )

            if levelState.leveledUp {
                await analyticsService.trackEvent(
                    .levelUp,
                    properties: [
                        "user_id": updatedProfile.id.uuidString,
                        "new_level": "\(updatedProfile.level)",
                        "xp_total": "\(updatedProfile.xp_total)",
                        "timestamp": Self.analyticsTimestamp(for: date)
                    ]
                )
            }

            RNFLogger.sync.info("operation=complete_reading result=success challenge_advanced=\(advancedChallenge != nil, privacy: .public)")
            return ReadingCompletionResult(
                upload: upload,
                dailyLog: completedLog,
                profile: updatedProfile,
                xpAwarded: awardedXP,
                levelState: levelState,
                advancedChallenge: advancedChallenge
            )
        } catch {
            RNFLogger.sync.error("operation=complete_reading result=failure error_category=\(RNFLogger.errorCategory(error), privacy: .public)")
            return nil
        }
    }

    private static func analyticsTimestamp(for date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

}
