import Foundation

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
    private let analyticsService: AnalyticsService
    private weak var gameState: GameState?

    init(
        workoutService: WorkoutService = WorkoutService(),
        dailyLogService: DailyLogService = DailyLogService(),
        xpService: XPService = XPService(),
        challengeEngine: ChallengeEngine? = nil,
        analyticsService: AnalyticsService = AnalyticsService()
    ) {
        self.workoutService = workoutService
        self.dailyLogService = dailyLogService
        self.xpService = xpService
        self.challengeEngine = challengeEngine ?? ChallengeEngine()
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
            let levelState = xpService.awardXP(
                currentTotal: updatedProfile.xp_total,
                gainedXP: Self.workoutXP
            )

            updatedProfile.xp_total = levelState.totalXP
            updatedProfile.level = levelState.level
            completedLog.xp_earned += Self.workoutXP

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
                    "user_id": updatedProfile.id.uuidString,
                    "duration": "\(durationSeconds)",
                    "xp_awarded": "\(Self.workoutXP)",
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

            return WorkoutCompletionResult(
                dailyLog: completedLog,
                profile: updatedProfile,
                xpAwarded: Self.workoutXP,
                levelState: levelState,
                advancedChallenge: advancedChallenge
            )
        } catch {
            return nil
        }
    }

    private static func analyticsTimestamp(for date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

}
