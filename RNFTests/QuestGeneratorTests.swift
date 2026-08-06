import XCTest
@testable import RNF

@MainActor
final class QuestGeneratorTests: XCTestCase {

    func testGenerateDailyQuestsSelectsMainQuestForWeakestStat() throws {
        var profile = Profile.placeholder
        profile.strength = 6
        profile.discipline = 6
        profile.focus = 1

        let strengthQuest = makeQuest(
            title: "Strength Quest",
            statStrength: 1
        )
        let focusQuest = makeQuest(
            title: "Focus Quest",
            statFocus: 1
        )

        let plan = QuestGenerator.generateDailyQuests(
            profile: profile,
            quests: [strengthQuest, focusQuest]
        )

        XCTAssertEqual(plan.main?.id, focusQuest.id)
        XCTAssertFalse(plan.side.map(\.id).contains(focusQuest.id))
    }

    func testWeeklyHabitUnlockIsUnavailableBeforeFirstWeek() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 3)))
        var profile = Profile.placeholder
        profile.created_at = try XCTUnwrap(calendar.date(byAdding: .day, value: -6, to: today))

        let weeklyQuest = makeQuest(
            title: "Weekly Walk",
            cadence: .weekly,
            statEnergy: 1
        )

        let selectedQuest = QuestGenerator.selectWeeklyHabitUnlock(
            profile: profile,
            quests: [weeklyQuest],
            asOf: today,
            calendar: calendar
        )

        XCTAssertNil(selectedQuest)
    }

    func testWeeklyHabitUnlockReturnsWeeklyQuestAfterFirstWeek() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 3)))
        var profile = Profile.placeholder
        profile.created_at = try XCTUnwrap(calendar.date(byAdding: .day, value: -7, to: today))

        let dailyQuest = makeQuest(
            title: "Daily Hydration",
            cadence: .daily,
            statEnergy: 1
        )
        let weeklyQuest = makeQuest(
            title: "Weekly Walk",
            cadence: .weekly,
            statEnergy: 1
        )

        let selectedQuest = QuestGenerator.selectWeeklyHabitUnlock(
            profile: profile,
            quests: [dailyQuest, weeklyQuest],
            asOf: today,
            calendar: calendar
        )

        XCTAssertEqual(selectedQuest?.id, weeklyQuest.id)
    }

    func testQuestServiceExposesDailyAndWeeklyPlans() {
        let service = QuestService()
        let plan = service.generateQuestPlan(for: .placeholder)

        XCTAssertFalse(plan.daily.habits.isEmpty)
        XCTAssertEqual(plan.daily.dailyGoal, QuestDifficultySystem.questsPerDay(for: 1))
        XCTAssertNil(plan.weekly.habit)
    }

    private func makeQuest(
        title: String,
        cadence: QuestCadence = .daily,
        statStrength: Int? = nil,
        statDiscipline: Int? = nil,
        statFocus: Int? = nil,
        statEnergy: Int? = nil,
        statWisdom: Int? = nil,
        statMind: Int? = nil,
        statSpirit: Int? = nil
    ) -> Quest {

        Quest(
            id: UUID(),
            title: title,
            description: title,
            stat_strength: statStrength,
            stat_discipline: statDiscipline,
            stat_focus: statFocus,
            stat_energy: statEnergy,
            stat_wisdom: statWisdom,
            stat_mind: statMind,
            stat_spirit: statSpirit,
            xp_reward: 10,
            difficulty: .easy,
            cadence: cadence,
            category: "test"
        )
    }

}
