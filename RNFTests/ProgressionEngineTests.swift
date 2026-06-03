import XCTest
@testable import RNF

@MainActor
final class ProgressionEngineTests: XCTestCase {

    func testProcessHabitCompletionRefreshesQuestPlan() async {
        let initialHabit = Habit(
            id: UUID(),
            name: "Drink Water",
            description: "Hydrate",
            xpReward: 10
        )
        let gameState = GameState()
        let engine = ProgressionEngine()

        gameState.apply(
            profile: .placeholder,
            levelState: XPSystem.levelState(for: 0),
            titles: [],
            quests: [initialHabit],
            dailyGoal: 2,
            dailyCompleted: 0,
            completedHabitIDs: [],
            dailyLog: .today(goal: 2)
        )
        engine.configure(gameState: gameState)

        let result = await engine.processHabitCompletion(habitId: initialHabit.id)

        XCTAssertNotNil(result)
        XCTAssertFalse(gameState.quests.isEmpty)
        XCTAssertFalse(gameState.quests.map(\.id).contains(initialHabit.id))
        XCTAssertEqual(gameState.dailyGoal, QuestDifficultySystem.questsPerDay(for: gameState.level))
        XCTAssertEqual(gameState.dailyLog.habits_required, gameState.dailyGoal)
        XCTAssertEqual(gameState.dailyCompleted, 1)
        XCTAssertEqual(gameState.completedHabitIDs, [initialHabit.id])
    }

}
