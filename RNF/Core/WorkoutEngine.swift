import Foundation
import os

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
            return nil
        }

        do {
            let existingLog = try await workoutService.dailyLogForWorkout(
                userId: gameState.profile.id,
                date: date
            )

            guard !existingLog.workout_completed else {
                return nil
            }

            var completedLog = try await workoutService.completeWorkout(
                userId: gameState.profile.id,
                date: date
            )

            var updatedProfile = gameState.profile
            let activePerks: ActivePerkSummary
            do {
                activePerks = try await skillTreeService.activePerks(for: updatedProfile)
            } catch {
                RNFLogger.sync.error("Failed to load active perks: \(error.localizedDescription)")
                activePerks = .empty
            }
            let awardedXP = PerkSystem.modifiedXPReward(
                baseXP: Self.workoutXP,
                activePerks: activePerks,
                currentDailyXP: completedLog.xp_earned,
                streak: updatedProfile.streak
            )
            let levelState = xpService.awardXP(
                currentTotal: updatedProfile.xp_total,
                gainedXP: awardedXP
            )

            updatedProfile.xp_total = levelState.totalXP
            updatedProfile.level = levelState.level
            completedLog.xp_earned += awardedXP

            await dailyLogService.saveDailyLog(completedLog)
            await dailyLogService.saveProfile(updatedProfile)

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
                .workoutCompleted,
                properties: [
                    "duration": "\(durationSeconds)",
                    "xp_awarded": "\(awardedXP)",
                    "timestamp": Self.analyticsTimestamp(for: date)
                ]
            )

            if levelState.leveledUp {
                await analyticsService.trackEvent(
                    .levelUp,
                    properties: [
                        "new_level": "\(updatedProfile.level)",
                        "xp_total": "\(updatedProfile.xp_total)",
                        "timestamp": Self.analyticsTimestamp(for: date)
                    ]
                )
            }

            return WorkoutCompletionResult(
                dailyLog: completedLog,
                profile: updatedProfile,
                xpAwarded: awardedXP,
                levelState: levelState,
                advancedChallenge: advancedChallenge
            )
        } catch {
            RNFLogger.dailyLog.error("WorkoutEngine.completeWorkout failed: \(error.localizedDescription)")
            return nil
        }
    }

    private static func analyticsTimestamp(for date: Date) -> String {
        AnalyticsTimestamp.string(for: date)
    }

}
