import XCTest
@testable import RNF

@MainActor
final class HabitAgencyServiceTests: XCTestCase {

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "rnf_selected_presets")
        UserDefaults.standard.removeObject(forKey: "rnf_custom_habits")
        super.tearDown()
    }

    // MARK: - Preset Selection

    func testSaveAndLoadSelections() {
        HabitAgencyService.saveSelections(["cold_shower", "read_10", "gratitude"])
        let loaded = HabitAgencyService.loadSelections()
        XCTAssertEqual(loaded, ["cold_shower", "read_10", "gratitude"])
    }

    func testLoadSelectionsReturnsEmptyByDefault() {
        UserDefaults.standard.removeObject(forKey: "rnf_selected_presets")
        XCTAssertEqual(HabitAgencyService.loadSelections(), [])
    }

    func testSelectedPresetsReturnsMatchingPresets() {
        HabitAgencyService.saveSelections(["cold_shower", "meditate"])
        let presets = HabitAgencyService.selectedPresets()
        XCTAssertEqual(presets.count, 2)
        XCTAssertTrue(presets.contains(where: { $0.id == "cold_shower" }))
        XCTAssertTrue(presets.contains(where: { $0.id == "meditate" }))
    }

    // MARK: - Custom Habits

    func testSaveAndLoadCustomHabits() {
        let habits = [CustomHabit(name: "Run 5k", stat: "strength")]
        HabitAgencyService.saveCustomHabits(habits)
        let loaded = HabitAgencyService.loadCustomHabits()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.name, "Run 5k")
        XCTAssertEqual(loaded.first?.stat, "strength")
        XCTAssertEqual(loaded.first?.xpReward, 10)
    }

    func testLoadCustomHabitsReturnsEmptyByDefault() {
        UserDefaults.standard.removeObject(forKey: "rnf_custom_habits")
        XCTAssertEqual(HabitAgencyService.loadCustomHabits(), [])
    }

    // MARK: - Unlock State

    func testCustomSlotsProgression() {
        XCTAssertEqual(HabitAgencyService.customSlots(forStreak: 0), 0)
        XCTAssertEqual(HabitAgencyService.customSlots(forStreak: 13), 0)
        XCTAssertEqual(HabitAgencyService.customSlots(forStreak: 14), 1)
        XCTAssertEqual(HabitAgencyService.customSlots(forStreak: 29), 1)
        XCTAssertEqual(HabitAgencyService.customSlots(forStreak: 30), 2)
        XCTAssertEqual(HabitAgencyService.customSlots(forStreak: 59), 2)
        XCTAssertEqual(HabitAgencyService.customSlots(forStreak: 60), 3)
        XCTAssertEqual(HabitAgencyService.customSlots(forStreak: 90), 3)
    }

    func testCanSwapRequiresStreak7() {
        XCTAssertFalse(HabitAgencyService.canSwap(forStreak: 0))
        XCTAssertFalse(HabitAgencyService.canSwap(forStreak: 6))
        XCTAssertTrue(HabitAgencyService.canSwap(forStreak: 7))
        XCTAssertTrue(HabitAgencyService.canSwap(forStreak: 30))
    }

    // MARK: - HabitPreset

    func testAllPresetsContains12Items() {
        XCTAssertEqual(HabitPreset.all.count, 12)
    }

    func testPresetsGroupedByCategory() {
        let body = HabitPreset.all.filter { $0.category == .body }
        let mind = HabitPreset.all.filter { $0.category == .mind }
        let spirit = HabitPreset.all.filter { $0.category == .spirit }
        XCTAssertEqual(body.count, 4)
        XCTAssertEqual(mind.count, 4)
        XCTAssertEqual(spirit.count, 4)
    }

    func testAllPresetIDsAreUnique() {
        let ids = HabitPreset.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }
}
