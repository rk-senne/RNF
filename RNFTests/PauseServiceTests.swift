import XCTest
@testable import RNF

@MainActor
final class PauseServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "rnf_pause_periods")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "rnf_pause_periods")
        super.tearDown()
    }

    // MARK: - Activation (P22-TST-03)

    func testActivateReturnsValidPausePeriod() {
        let period = PauseService.activate(days: 7, cycleID: "cycle_1")

        XCTAssertNotNil(period)
        XCTAssertEqual(period?.cycleID, "cycle_1")
        XCTAssertEqual(period?.durationDays, 7)
    }

    func testActivateStoresPeriod() {
        PauseService.activate(days: 5, cycleID: "cycle_1")

        let periods = PauseService.allPeriods()
        XCTAssertEqual(periods.count, 1)
        XCTAssertEqual(periods.first?.cycleID, "cycle_1")
    }

    // MARK: - 1/Cycle Limit Validation (P22-TST-03)

    func testCannotActivateTwiceInSameCycle() {
        let first = PauseService.activate(days: 3, cycleID: "cycle_1")
        let second = PauseService.activate(days: 5, cycleID: "cycle_1")

        XCTAssertNotNil(first)
        XCTAssertNil(second, "Second pause in same cycle should be rejected")
    }

    func testCanActivateInDifferentCycles() {
        let first = PauseService.activate(days: 3, cycleID: "cycle_1")
        let second = PauseService.activate(days: 5, cycleID: "cycle_2")

        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
        XCTAssertEqual(PauseService.allPeriods().count, 2)
    }

    func testHasUsedPauseReturnsTrueAfterActivation() {
        PauseService.activate(days: 3, cycleID: "cycle_1")

        XCTAssertTrue(PauseService.hasUsedPause(forCycle: "cycle_1"))
    }

    func testHasUsedPauseReturnsFalseForUnusedCycle() {
        PauseService.activate(days: 3, cycleID: "cycle_1")

        XCTAssertFalse(PauseService.hasUsedPause(forCycle: "cycle_2"))
    }

    // MARK: - 14-Day Max Validation (P22-TST-03)

    func testActivateRejectsMoreThan14Days() {
        let period = PauseService.activate(days: 15, cycleID: "cycle_1")
        XCTAssertNil(period, "Should reject duration > 14 days")
    }

    func testActivateRejectsZeroDays() {
        let period = PauseService.activate(days: 0, cycleID: "cycle_1")
        XCTAssertNil(period, "Should reject 0 days")
    }

    func testActivateRejectsNegativeDays() {
        let period = PauseService.activate(days: -1, cycleID: "cycle_1")
        XCTAssertNil(period, "Should reject negative days")
    }

    func testActivateAccepts14Days() {
        let period = PauseService.activate(days: 14, cycleID: "cycle_1")
        XCTAssertNotNil(period, "Should accept exactly 14 days")
    }

    func testActivateAccepts1Day() {
        let period = PauseService.activate(days: 1, cycleID: "cycle_1")
        XCTAssertNotNil(period, "Should accept exactly 1 day")
    }

    // MARK: - Streak Preservation During Pause (P22-TST-03)

    func testIsCurrentlyPausedReturnsTrueDuringActivePause() {
        PauseService.activate(days: 7, cycleID: "cycle_1")

        XCTAssertTrue(PauseService.isCurrentlyPaused())
    }

    func testIsCurrentlyPausedReturnsFalseWhenNoPause() {
        XCTAssertFalse(PauseService.isCurrentlyPaused())
    }

    func testIsPausedOnDateReturnsTrueForDateWithinPause() {
        PauseService.activate(days: 7, cycleID: "cycle_1")

        let now = Date()
        XCTAssertTrue(PauseService.isPaused(on: now))
    }

    func testIsPausedOnDateReturnsFalseForDateOutsidePause() {
        PauseService.activate(days: 1, cycleID: "cycle_1")

        // A date 10 days from now should be outside the 1-day pause
        let futureDate = Date().addingTimeInterval(10 * 24 * 60 * 60)
        XCTAssertFalse(PauseService.isPaused(on: futureDate))
    }

    func testActivePauseReturnsCurrentPeriod() {
        PauseService.activate(days: 5, cycleID: "cycle_1")

        let active = PauseService.activePause()
        XCTAssertNotNil(active)
        XCTAssertEqual(active?.cycleID, "cycle_1")
    }

    func testActivePauseReturnsNilWhenNoPause() {
        XCTAssertNil(PauseService.activePause())
    }

    // MARK: - Retroactive Pause

    func testRetroactivePauseBackdatesStart() {
        let period = PauseService.activateRetroactive(missedDays: 5, cycleID: "cycle_1")

        XCTAssertNotNil(period)
        // Start should be approximately 5 days ago
        let fiveDaysAgo = Date().addingTimeInterval(-5 * 24 * 60 * 60)
        let diff = abs(period!.startDate.timeIntervalSince(fiveDaysAgo))
        XCTAssertLessThan(diff, 5, "Start should be ~5 days ago")
    }

    func testRetroactivePauseClampsTo14Days() {
        let period = PauseService.activateRetroactive(missedDays: 30, cycleID: "cycle_1")

        XCTAssertNotNil(period)
        XCTAssertLessThanOrEqual(period!.durationDays, 14)
    }

    func testRetroactivePauseRespectsOncePerCycle() {
        PauseService.activate(days: 3, cycleID: "cycle_1")
        let retro = PauseService.activateRetroactive(missedDays: 5, cycleID: "cycle_1")

        XCTAssertNil(retro, "Retroactive should be rejected if cycle already used")
    }

    // MARK: - Query Methods

    func testTotalPausedDaysAcrossCycles() {
        PauseService.activate(days: 3, cycleID: "cycle_1")
        PauseService.activate(days: 7, cycleID: "cycle_2")

        let total = PauseService.totalPausedDays()
        XCTAssertEqual(total, 10)
    }

    func testAllPeriodsReturnsSortedByStartDateDescending() {
        PauseService.activate(days: 2, cycleID: "cycle_1")
        // Small delay to ensure different timestamps
        PauseService.activate(days: 3, cycleID: "cycle_2")

        let periods = PauseService.allPeriods()
        XCTAssertEqual(periods.count, 2)

        if periods.count == 2 {
            XCTAssertGreaterThanOrEqual(
                periods[0].startDate,
                periods[1].startDate,
                "Should be sorted descending by start date"
            )
        }
    }
}
