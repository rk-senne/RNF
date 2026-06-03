import XCTest
@testable import RNF

@MainActor
final class ProgressionEngineTests: XCTestCase {

    func testProcessHabitCompletionRefreshesQuestPlan() async throws {
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

        let progressionResult = try XCTUnwrap(result)
        XCTAssertFalse(progressionResult.questPlan.habits.isEmpty)
        XCTAssertFalse(progressionResult.questPlan.habits.map(\.id).contains(initialHabit.id))
        XCTAssertEqual(progressionResult.questPlan.dailyGoal, QuestDifficultySystem.questsPerDay(for: progressionResult.levelState.level))
        XCTAssertEqual(progressionResult.updatedDailyLog.habits_required, progressionResult.questPlan.dailyGoal)
        XCTAssertEqual(progressionResult.updatedDailyLog.habits_completed, 1)
        XCTAssertEqual(progressionResult.completedHabitIDs, [initialHabit.id])
    }

    func testProcessHabitCompletionReturnsFullStateTransitionPayload() async throws {
        let habit = Habit(
            id: UUID(),
            name: "Drink Water",
            description: "Hydrate",
            xpReward: 10
        )
        var profile = Profile.placeholder
        profile.xp_total = 190
        profile.level = 1
        profile.streak = 2

        let gameState = GameState()
        let engine = ProgressionEngine()

        gameState.apply(
            profile: profile,
            levelState: XPSystem.levelState(for: profile.xp_total),
            titles: [],
            quests: [habit],
            dailyGoal: 1,
            dailyCompleted: 0,
            completedHabitIDs: [],
            dailyLog: .today(goal: 1)
        )
        engine.configure(gameState: gameState)

        let completionResult = await engine.processHabitCompletion(habitId: habit.id)
        let result = try XCTUnwrap(completionResult)

        XCTAssertEqual(result.habit.id, habit.id)
        XCTAssertEqual(result.updatedProfile.xp_total, 200)
        XCTAssertEqual(result.updatedProfile.level, 2)
        XCTAssertEqual(result.updatedProfile.streak, 3)
        XCTAssertEqual(result.updatedProfile.energy, profile.energy + 1)
        XCTAssertEqual(result.updatedDailyLog.habits_completed, 1)
        XCTAssertEqual(result.updatedDailyLog.xp_earned, habit.xpReward)
        XCTAssertEqual(result.updatedDailyLog.status, .complete)
        XCTAssertEqual(result.questPlan.dailyGoal, QuestDifficultySystem.questsPerDay(for: result.levelState.level))
        XCTAssertFalse(result.questPlan.habits.isEmpty)
        XCTAssertEqual(result.completedHabitIDs, [habit.id])
        XCTAssertEqual(result.xpGained, habit.xpReward)
        XCTAssertEqual(result.levelState.totalXP, 200)
        XCTAssertEqual(result.levelState.level, 2)
        XCTAssertTrue(result.leveledUp)
        XCTAssertTrue(result.missionCompleted)
        XCTAssertEqual(result.unlockedBadge, "Ember Initiate")
    }

}
