import Foundation

struct ProgressionInput {

    let profile: Profile
    let quests: [Habit]
    let completedHabitIDs: Set<UUID>
    let dailyCompleted: Int
    let dailyGoal: Int
    let dailyLog: DailyLog

    init(
        profile: Profile,
        quests: [Habit],
        completedHabitIDs: Set<UUID>,
        dailyCompleted: Int,
        dailyGoal: Int,
        dailyLog: DailyLog
    ) {
        self.profile = profile
        self.quests = quests
        self.completedHabitIDs = completedHabitIDs
        self.dailyCompleted = dailyCompleted
        self.dailyGoal = dailyGoal
        self.dailyLog = dailyLog
    }

    @MainActor
    init(gameState: GameState) {
        self.init(
            profile: gameState.profile,
            quests: gameState.quests,
            completedHabitIDs: gameState.completedHabitIDs,
            dailyCompleted: gameState.dailyCompleted,
            dailyGoal: gameState.dailyGoal,
            dailyLog: gameState.dailyLog
        )
    }

}
