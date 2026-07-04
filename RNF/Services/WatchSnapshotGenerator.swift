import Foundation

enum WatchSnapshotGenerator {

    @MainActor
    static func generate(from gameState: GameState) -> WatchDailySnapshot {
        WatchDailySnapshot(
            date: Date(),
            level: gameState.level,
            streak: gameState.streak,
            dailyCompleted: gameState.dailyCompleted,
            dailyGoal: gameState.dailyGoal,
            challengeDay: nil,
            habits: gameState.quests.map { habit in
                WatchHabitSummary(
                    id: habit.id,
                    name: habit.name,
                    completed: gameState.completedHabitIDs.contains(habit.id),
                    xpReward: habit.xpReward
                )
            }
        )
    }
}
