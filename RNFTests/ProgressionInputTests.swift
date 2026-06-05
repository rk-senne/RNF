import XCTest
@testable import RNF

@MainActor
final class ProgressionInputTests: XCTestCase {

    func testSnapshotCapturesCurrentGameStateProgressionFields() {
        let completedHabitID = UUID()
        let activeHabit = Habit(
            id: UUID(),
            name: "Train",
            description: "Workout",
            xpReward: 15
        )
        var profile = Profile.placeholder
        profile.xp_total = 190
        profile.level = 1
        profile.streak = 3

        let dailyLog = DailyLog(
            id: UUID(),
            user_id: nil,
            date: Date(timeIntervalSince1970: 1_750_000_000),
            habits_completed: 1,
            habits_required: 2,
            workout_completed: false,
            reading_completed: true,
            forgiveness_used: false,
            xp_earned: 20,
            status: .partial,
            created_at: nil
        )

        let gameState = GameState()
        gameState.apply(
            profile: profile,
            levelState: XPSystem.levelState(for: profile.xp_total),
            titles: ["Ember"],
            quests: [activeHabit],
            dailyGoal: dailyLog.habits_required,
            dailyCompleted: dailyLog.habits_completed,
            completedHabitIDs: [completedHabitID],
            dailyLog: dailyLog
        )

        let input = ProgressionInput(gameState: gameState)

        XCTAssertEqual(input.profile.id, profile.id)
        XCTAssertEqual(input.profile.xp_total, profile.xp_total)
        XCTAssertEqual(input.profile.level, profile.level)
        XCTAssertEqual(input.profile.streak, profile.streak)
        XCTAssertEqual(input.quests.map(\.id), [activeHabit.id])
        XCTAssertEqual(input.completedHabitIDs, [completedHabitID])
        XCTAssertEqual(input.dailyCompleted, dailyLog.habits_completed)
        XCTAssertEqual(input.dailyGoal, dailyLog.habits_required)
        XCTAssertEqual(input.dailyLog.id, dailyLog.id)
        XCTAssertEqual(input.dailyLog.xp_earned, dailyLog.xp_earned)
        XCTAssertEqual(input.dailyLog.status, dailyLog.status)
    }

    func testSnapshotIsDetachedFromLaterGameStateChanges() {
        let originalHabit = Habit(
            id: UUID(),
            name: "Hydrate",
            description: nil,
            xpReward: 10
        )
        let replacementHabit = Habit(
            id: UUID(),
            name: "Read",
            description: nil,
            xpReward: 10
        )
        var originalProfile = Profile.placeholder
        originalProfile.xp_total = 40

        let gameState = GameState()
        gameState.apply(
            profile: originalProfile,
            levelState: XPSystem.levelState(for: originalProfile.xp_total),
            titles: [],
            quests: [originalHabit],
            dailyGoal: 2,
            dailyCompleted: 1,
            completedHabitIDs: [originalHabit.id],
            dailyLog: .today(goal: 2)
        )

        let input = ProgressionInput(gameState: gameState)

        var replacementProfile = originalProfile
        replacementProfile.xp_total = 120
        gameState.apply(
            profile: replacementProfile,
            levelState: XPSystem.levelState(for: replacementProfile.xp_total),
            titles: [],
            quests: [replacementHabit],
            dailyGoal: 4,
            dailyCompleted: 0,
            completedHabitIDs: [],
            dailyLog: .today(goal: 4)
        )

        XCTAssertEqual(input.profile.xp_total, originalProfile.xp_total)
        XCTAssertEqual(input.quests.map(\.id), [originalHabit.id])
        XCTAssertEqual(input.completedHabitIDs, [originalHabit.id])
        XCTAssertEqual(input.dailyCompleted, 1)
        XCTAssertEqual(input.dailyGoal, 2)
    }

}
