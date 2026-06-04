import Foundation
import OSLog

struct WorkoutCompletionResult {

    let dailyLog: DailyLog
    let profile: Profile
    let xpAwarded: Int
    let levelState: XPSystem.LevelState
    let advancedChallenge: Challenge?

}

@MainActor
final class WorkoutEngine {

    private static let workoutXP = 15

    private let workoutService: WorkoutService
    private let dailyLogService: DailyLogService
    private let xpService: XPService
    private let challengeEngine: ChallengeEngine
    private let skillTreeService: SkillTreeService
    private let analyticsService: AnalyticsService
    private weak var gameState: GameState?

    init(
        workoutService: WorkoutService = WorkoutService(),
        dailyLogService: DailyLogService = DailyLogService(),
        xpService: XPService = XPService(),
        challengeEngine: ChallengeEngine? = nil,
        skillTreeService: SkillTreeService = SkillTreeService(),
        analyticsService: AnalyticsService = AnalyticsService()
    ) {
        self.workoutService = workoutService
        self.dailyLogService = dailyLogService
        self.xpService = xpService
        self.challengeEngine = challengeEngine ?? ChallengeEngine()
        self.skillTreeService = skillTreeService
        self.analyticsService = analyticsService
    }

    func configure(gameState: GameState) {
        self.gameState = gameState
    }

    func completeWorkout(
        durationSeconds: Int,
        elapsedSeconds: Int,
        date: Date = Date()
    ) async -> WorkoutCompletionResult? {

        guard
            WorkoutDurationValidator.isComplete(
                durationSeconds: durationSeconds,
                elapsedSeconds: elapsedSeconds
            ),
            let gameState,
            !gameState.profile.isPlaceholder
        else {
            RNFLogger.sync.info("operation=complete_workout result=skipped reason=invalid_or_placeholder")
            return nil
        }

        do {
            let existingLog = try await workoutService.dailyLogForWorkout(
                userId: gameState.profile.id,
                date: date
            )

            guard !existingLog.workout_completed else {
                RNFLogger.sync.info("operation=complete_workout result=skipped reason=duplicate")
                return nil
            }

            var completedLog = try await workoutService.completeWorkout(
                userId: gameState.profile.id,
                date: date
            )

            var updatedProfile = gameState.profile
            let activePerks = (try? await skillTreeService.activePerks(for: updatedProfile)) ?? .empty
            let awardedXP = PerkSystem.modifiedXPReward(
                baseXP: Self.workoutXP,
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
                RNFLogger.sync.error("operation=complete_workout result=failure step=save_state daily_log_state=\(String(describing: dailyLogSaveResult.saveState), privacy: .public) profile_state=\(String(describing: profileSaveResult.saveState), privacy: .public)")
                return nil
            }

            let advancedChallenge = await challengeEngine.advanceIfDayComplete(
                userId: updatedProfile.id,
                date: date
            )

            await analyticsService.trackEvent(
                .workoutCompleted,
                properties: [
                    "user_id": updatedProfile.id.uuidString,
                    "duration": "\(durationSeconds)",
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

            RNFLogger.sync.info("operation=complete_workout result=success challenge_advanced=\(advancedChallenge != nil, privacy: .public)")
            return WorkoutCompletionResult(
                dailyLog: completedLog,
                profile: updatedProfile,
                xpAwarded: awardedXP,
                levelState: levelState,
                advancedChallenge: advancedChallenge
            )
        } catch {
            RNFLogger.sync.error("operation=complete_workout result=failure error_category=\(RNFLogger.errorCategory(error), privacy: .public)")
            return nil
        }
    }

    private static func analyticsTimestamp(for date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

}
