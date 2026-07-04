import XCTest
@testable import RNF

/// P25-TST-01: Tests for AdaptiveTimingService — median calculation and drift detection.
final class AdaptiveTimingServiceTests: XCTestCase {

    private let medianKey = "rnf_adaptive_timing_weekday_median"
    private let weekendMedianKey = "rnf_adaptive_timing_weekend_median"
    private let lastDriftCheckKey = "rnf_adaptive_timing_last_drift_check"
    private let previousMedianKey = "rnf_adaptive_timing_previous_median"

    override func setUp() {
        super.setUp()
        clearDefaults()
    }

    override func tearDown() {
        clearDefaults()
        super.tearDown()
    }

    private func clearDefaults() {
        UserDefaults.standard.removeObject(forKey: medianKey)
        UserDefaults.standard.removeObject(forKey: weekendMedianKey)
        UserDefaults.standard.removeObject(forKey: lastDriftCheckKey)
        UserDefaults.standard.removeObject(forKey: previousMedianKey)
    }

    // MARK: - Median Calculation (Odd Count)

    func testMedianWithOddCountReturnsMiddleValue() {
        // 5 timestamps: 7:00, 7:15, 7:30, 7:45, 8:00
        let timestamps: [TimeInterval] = [
            minutesSinceMidnight(7, 0),
            minutesSinceMidnight(7, 15),
            minutesSinceMidnight(7, 30),
            minutesSinceMidnight(7, 45),
            minutesSinceMidnight(8, 0)
        ]

        let median = AdaptiveTimingService.computeMedian(timestamps)

        // Median of [420, 435, 450, 465, 480] = 450 (7:30)
        XCTAssertEqual(median, minutesSinceMidnight(7, 30), accuracy: 0.01)
    }

    func testMedianWithThreeValuesReturnsMiddle() {
        let timestamps: [TimeInterval] = [
            minutesSinceMidnight(6, 0),
            minutesSinceMidnight(8, 0),
            minutesSinceMidnight(10, 0)
        ]

        let median = AdaptiveTimingService.computeMedian(timestamps)

        XCTAssertEqual(median, minutesSinceMidnight(8, 0), accuracy: 0.01)
    }

    func testMedianWithSingleValueReturnsThatValue() {
        let timestamps: [TimeInterval] = [minutesSinceMidnight(9, 30)]

        let median = AdaptiveTimingService.computeMedian(timestamps)

        XCTAssertEqual(median, minutesSinceMidnight(9, 30), accuracy: 0.01)
    }

    // MARK: - Median Calculation (Even Count)

    func testMedianWithEvenCountReturnsAverageOfMiddleTwo() {
        // 4 timestamps: 7:00, 7:20, 7:40, 8:00
        let timestamps: [TimeInterval] = [
            minutesSinceMidnight(7, 0),
            minutesSinceMidnight(7, 20),
            minutesSinceMidnight(7, 40),
            minutesSinceMidnight(8, 0)
        ]

        let median = AdaptiveTimingService.computeMedian(timestamps)

        // Average of 440 and 460 = 450 (7:30)
        XCTAssertEqual(median, minutesSinceMidnight(7, 30), accuracy: 0.01)
    }

    func testMedianWithTwoValuesReturnsAverage() {
        let timestamps: [TimeInterval] = [
            minutesSinceMidnight(6, 0),
            minutesSinceMidnight(10, 0)
        ]

        let median = AdaptiveTimingService.computeMedian(timestamps)

        // Average of 360 and 600 = 480 (8:00)
        XCTAssertEqual(median, minutesSinceMidnight(8, 0), accuracy: 0.01)
    }

    func testMedianWithSixValuesAveragesMiddleTwo() {
        // 6 timestamps: 6:00, 6:30, 7:00, 7:30, 8:00, 8:30
        let timestamps: [TimeInterval] = [
            minutesSinceMidnight(6, 0),
            minutesSinceMidnight(6, 30),
            minutesSinceMidnight(7, 0),
            minutesSinceMidnight(7, 30),
            minutesSinceMidnight(8, 0),
            minutesSinceMidnight(8, 30)
        ]

        let median = AdaptiveTimingService.computeMedian(timestamps)

        // Sorted middle two: 7:00 (420) and 7:30 (450) → avg = 435 (7:15)
        XCTAssertEqual(median, minutesSinceMidnight(7, 15), accuracy: 0.01)
    }

    // MARK: - Empty Input

    func testMedianWithEmptyArrayReturnsNil() {
        let median = AdaptiveTimingService.computeMedian([])
        XCTAssertNil(median)
    }

    // MARK: - Unsorted Input

    func testMedianSortsBeforeComputing() {
        // Out of order: 8:00, 6:00, 7:00
        let timestamps: [TimeInterval] = [
            minutesSinceMidnight(8, 0),
            minutesSinceMidnight(6, 0),
            minutesSinceMidnight(7, 0)
        ]

        let median = AdaptiveTimingService.computeMedian(timestamps)

        XCTAssertEqual(median, minutesSinceMidnight(7, 0), accuracy: 0.01)
    }

    // MARK: - Drift Detection

    func testDriftDetectedWhenShiftExceeds30Minutes() {
        let previousMedian = minutesSinceMidnight(7, 0)
        let currentMedian = minutesSinceMidnight(7, 35)

        let driftDetected = AdaptiveTimingService.isDriftDetected(
            previousMedian: previousMedian,
            currentMedian: currentMedian,
            thresholdMinutes: 30
        )

        XCTAssertTrue(driftDetected, "35-minute shift should trigger drift detection")
    }

    func testNoDriftWhenShiftIsExactly30Minutes() {
        let previousMedian = minutesSinceMidnight(7, 0)
        let currentMedian = minutesSinceMidnight(7, 30)

        let driftDetected = AdaptiveTimingService.isDriftDetected(
            previousMedian: previousMedian,
            currentMedian: currentMedian,
            thresholdMinutes: 30
        )

        XCTAssertFalse(driftDetected, "Exactly 30-minute shift should NOT trigger (requires > 30)")
    }

    func testNoDriftWhenShiftIsUnder30Minutes() {
        let previousMedian = minutesSinceMidnight(7, 0)
        let currentMedian = minutesSinceMidnight(7, 20)

        let driftDetected = AdaptiveTimingService.isDriftDetected(
            previousMedian: previousMedian,
            currentMedian: currentMedian,
            thresholdMinutes: 30
        )

        XCTAssertFalse(driftDetected, "20-minute shift should NOT trigger drift detection")
    }

    func testDriftDetectedWhenShiftIsNegative() {
        // User moved earlier (e.g., 8:00 → 7:00 = -60 min shift)
        let previousMedian = minutesSinceMidnight(8, 0)
        let currentMedian = minutesSinceMidnight(7, 0)

        let driftDetected = AdaptiveTimingService.isDriftDetected(
            previousMedian: previousMedian,
            currentMedian: currentMedian,
            thresholdMinutes: 30
        )

        XCTAssertTrue(driftDetected, "60-minute backward shift should trigger drift detection")
    }

    func testDriftDetectionUsesAbsoluteValue() {
        // Shift from 7:00 to 6:25 = -35 minutes
        let previousMedian = minutesSinceMidnight(7, 0)
        let currentMedian = minutesSinceMidnight(6, 25)

        let driftDetected = AdaptiveTimingService.isDriftDetected(
            previousMedian: previousMedian,
            currentMedian: currentMedian,
            thresholdMinutes: 30
        )

        XCTAssertTrue(driftDetected, "Absolute value of 35-minute shift should trigger")
    }

    // MARK: - Adaptive Notification Time

    func testAdaptiveTimeSubtractsFiveMinutesFromMedian() {
        let median = minutesSinceMidnight(7, 30)

        let adaptiveTime = AdaptiveTimingService.notificationTime(forMedian: median)

        XCTAssertEqual(adaptiveTime, minutesSinceMidnight(7, 25), accuracy: 0.01)
    }

    // MARK: - Outlier Filtering

    func testOutlierFilterRemovesTimestampsBetweenMidnightAnd4AM() {
        let timestamps: [TimeInterval] = [
            minutesSinceMidnight(0, 30),   // 00:30 - outlier
            minutesSinceMidnight(2, 0),    // 02:00 - outlier
            minutesSinceMidnight(3, 59),   // 03:59 - outlier
            minutesSinceMidnight(7, 0),    // 07:00 - valid
            minutesSinceMidnight(7, 30),   // 07:30 - valid
            minutesSinceMidnight(8, 0)     // 08:00 - valid
        ]

        let filtered = AdaptiveTimingService.filterOutliers(timestamps)

        XCTAssertEqual(filtered.count, 3)
        XCTAssertEqual(filtered[0], minutesSinceMidnight(7, 0), accuracy: 0.01)
    }

    func testOutlierFilterKeepsTimestampsAt4AMAndLater() {
        let timestamps: [TimeInterval] = [
            minutesSinceMidnight(4, 0),    // 04:00 - valid (boundary)
            minutesSinceMidnight(7, 0)     // 07:00 - valid
        ]

        let filtered = AdaptiveTimingService.filterOutliers(timestamps)

        XCTAssertEqual(filtered.count, 2)
    }

    // MARK: - Minimum Data Threshold

    func testRequiresMinimumFiveDataPointsPerPartition() {
        let fewTimestamps: [TimeInterval] = [
            minutesSinceMidnight(7, 0),
            minutesSinceMidnight(7, 15),
            minutesSinceMidnight(7, 30),
            minutesSinceMidnight(7, 45)
        ]

        let hasEnoughData = AdaptiveTimingService.meetsMinimumThreshold(fewTimestamps, minimum: 5)
        XCTAssertFalse(hasEnoughData)
    }

    func testMeetsMinimumThresholdWithExactlyFivePoints() {
        let timestamps: [TimeInterval] = [
            minutesSinceMidnight(7, 0),
            minutesSinceMidnight(7, 15),
            minutesSinceMidnight(7, 30),
            minutesSinceMidnight(7, 45),
            minutesSinceMidnight(8, 0)
        ]

        let hasEnoughData = AdaptiveTimingService.meetsMinimumThreshold(timestamps, minimum: 5)
        XCTAssertTrue(hasEnoughData)
    }

    // MARK: - Helpers

    /// Converts hours and minutes to minutes-since-midnight (as TimeInterval in minutes).
    private func minutesSinceMidnight(_ hours: Int, _ minutes: Int) -> TimeInterval {
        TimeInterval(hours * 60 + minutes)
    }
}
