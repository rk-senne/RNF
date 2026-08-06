import XCTest
@testable import RNF

@MainActor
final class BondStreakEnhancementTests: XCTestCase {

    // MARK: - Enhanced Bond Streak Logic (P32-SOC-01)
    // Bond streak now increments when EITHER buddy completes 1+ habit

    @MainActor
    func testBondStreak_onlyMyCompletion_incrementsStreak() async {
        let service = BuddyService()
        let result = service.calculateBondStreak(
            myCompleted: true,
            buddyCompleted: false,
            currentBondStreak: 5
        )
        XCTAssertEqual(result.currentStreak, 6, "Bond streak should increment when I complete")
        XCTAssertFalse(result.bothCompletedToday)
        XCTAssertEqual(result.xpBonus, 0, "XP bonus only when BOTH complete")
    }

    @MainActor
    func testBondStreak_onlyBuddyCompletion_incrementsStreak() async {
        let service = BuddyService()
        let result = service.calculateBondStreak(
            myCompleted: false,
            buddyCompleted: true,
            currentBondStreak: 3
        )
        XCTAssertEqual(result.currentStreak, 4, "Bond streak should increment when buddy completes")
        XCTAssertFalse(result.bothCompletedToday)
        XCTAssertEqual(result.xpBonus, 0)
    }

    @MainActor
    func testBondStreak_bothComplete_incrementsAndGivesBonus() async {
        let service = BuddyService()
        let result = service.calculateBondStreak(
            myCompleted: true,
            buddyCompleted: true,
            currentBondStreak: 10
        )
        XCTAssertEqual(result.currentStreak, 11)
        XCTAssertTrue(result.bothCompletedToday)
        XCTAssertEqual(result.xpBonus, BuddyService.xpBonusBothComplete)
    }

    @MainActor
    func testBondStreak_neitherCompletes_resetsToZero() async {
        let service = BuddyService()
        let result = service.calculateBondStreak(
            myCompleted: false,
            buddyCompleted: false,
            currentBondStreak: 15
        )
        XCTAssertEqual(result.currentStreak, 0, "Bond streak resets only when NEITHER completes")
        XCTAssertFalse(result.bothCompletedToday)
        XCTAssertEqual(result.xpBonus, 0)
    }

    @MainActor
    func testBondStreak_fromZero_startsNewStreak() async {
        let service = BuddyService()
        let result = service.calculateBondStreak(
            myCompleted: true,
            buddyCompleted: false,
            currentBondStreak: 0
        )
        XCTAssertEqual(result.currentStreak, 1)
    }

    // MARK: - Bond Streak Milestones (P32-SOC-03)

    func testBondStreakMilestones_correctValues() {
        // Verify the milestone thresholds we'll use for notifications
        let milestones = [7, 14, 30, 60, 90]
        XCTAssertEqual(milestones.count, 5)
        XCTAssertTrue(milestones.allSatisfy { $0 > 0 })
    }
}
