import XCTest
@testable import RNF

/// P25-TST-04: Tests for EngagementStateManager — state transitions and push safeguards.
final class EngagementStateTests: XCTestCase {

    private let stateKey = "rnf_engagement_state"
    private let lastOpenKey = "rnf_engagement_last_open"
    private let pushCountKey = "rnf_engagement_pushes_30d"
    private let lastPushKey = "rnf_engagement_last_push"
    private let stateEnteredKey = "rnf_engagement_state_entered"

    override func setUp() {
        super.setUp()
        clearDefaults()
    }

    override func tearDown() {
        clearDefaults()
        super.tearDown()
    }

    private func clearDefaults() {
        UserDefaults.standard.removeObject(forKey: stateKey)
        UserDefaults.standard.removeObject(forKey: lastOpenKey)
        UserDefaults.standard.removeObject(forKey: pushCountKey)
        UserDefaults.standard.removeObject(forKey: lastPushKey)
        UserDefaults.standard.removeObject(forKey: stateEnteredKey)
    }

    // MARK: - State Transitions: Engaged → AtRisk

    func testEngagedTransitionsToAtRiskAfterNoOpenFor1Day() {
        let lastOpen = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        let newState = EngagementStateManager.computeState(
            currentState: .engaged,
            lastOpenDate: lastOpen,
            recentCompletionRate: 0.0,
            now: Date()
        )

        XCTAssertEqual(newState, .atRisk)
    }

    func testEngagedRemainsEngagedWhenOpenedToday() {
        let lastOpen = Date()

        let newState = EngagementStateManager.computeState(
            currentState: .engaged,
            lastOpenDate: lastOpen,
            recentCompletionRate: 0.60,
            now: Date()
        )

        XCTAssertEqual(newState, .engaged)
    }

    func testEngagedTransitionsToAtRiskWhenOpenButZeroCompletionsFor2Days() {
        // Opened today but 0 completions for 2 consecutive days
        let lastOpen = Date()

        let newState = EngagementStateManager.computeState(
            currentState: .engaged,
            lastOpenDate: lastOpen,
            recentCompletionRate: 0.0,
            consecutiveZeroCompletionDays: 2,
            now: Date()
        )

        XCTAssertEqual(newState, .atRisk)
    }

    // MARK: - State Transitions: AtRisk → Drifting

    func testAtRiskTransitionsToDriftingAfterNoOpenFor2Days() {
        let lastOpen = Calendar.current.date(byAdding: .day, value: -2, to: Date())!

        let newState = EngagementStateManager.computeState(
            currentState: .atRisk,
            lastOpenDate: lastOpen,
            recentCompletionRate: 0.0,
            now: Date()
        )

        XCTAssertEqual(newState, .drifting)
    }

    // MARK: - State Transitions: Drifting → Lapsed

    func testDriftingTransitionsToLapsedAfterNoOpenFor4Days() {
        let lastOpen = Calendar.current.date(byAdding: .day, value: -4, to: Date())!

        let newState = EngagementStateManager.computeState(
            currentState: .drifting,
            lastOpenDate: lastOpen,
            recentCompletionRate: 0.0,
            now: Date()
        )

        XCTAssertEqual(newState, .lapsed)
    }

    // MARK: - State Transitions: Lapsed → Churned

    func testLapsedTransitionsToChurnedAfterNoOpenFor7Days() {
        let lastOpen = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

        let newState = EngagementStateManager.computeState(
            currentState: .lapsed,
            lastOpenDate: lastOpen,
            recentCompletionRate: 0.0,
            now: Date()
        )

        XCTAssertEqual(newState, .churned)
    }

    // MARK: - Recovery: Any → Engaged

    func testDriftingReturnsToEngagedOnAppOpen() {
        let lastOpen = Date()

        let newState = EngagementStateManager.computeState(
            currentState: .drifting,
            lastOpenDate: lastOpen,
            recentCompletionRate: 0.50,
            now: Date()
        )

        XCTAssertEqual(newState, .engaged)
    }

    func testLapsedReturnsToEngagedOnAppOpen() {
        let lastOpen = Date()

        let newState = EngagementStateManager.computeState(
            currentState: .lapsed,
            lastOpenDate: lastOpen,
            recentCompletionRate: 0.50,
            now: Date()
        )

        XCTAssertEqual(newState, .engaged)
    }

    func testChurnedReturnsToEngagedOnAppOpen() {
        let lastOpen = Date()

        let newState = EngagementStateManager.computeState(
            currentState: .churned,
            lastOpenDate: lastOpen,
            recentCompletionRate: 0.50,
            now: Date()
        )

        XCTAssertEqual(newState, .engaged)
    }

    // MARK: - Push Safeguards: Maximum 5 per 30 Days

    func testCanSendPushWhenCountBelowLimit() {
        let canSend = EngagementStateManager.canSendPush(
            pushesSent30Days: 4,
            lastPushDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
            now: Date()
        )

        XCTAssertTrue(canSend)
    }

    func testCannotSendPushWhenCountAtLimit() {
        let canSend = EngagementStateManager.canSendPush(
            pushesSent30Days: 5,
            lastPushDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
            now: Date()
        )

        XCTAssertFalse(canSend, "Should NOT send push when 5 already sent in 30 days")
    }

    func testCannotSendPushWhenCountExceedsLimit() {
        let canSend = EngagementStateManager.canSendPush(
            pushesSent30Days: 7,
            lastPushDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
            now: Date()
        )

        XCTAssertFalse(canSend, "Should NOT send push when count > 5")
    }

    // MARK: - Push Safeguards: 48-Hour Cooldown

    func testCannotSendPushWithin48Hours() {
        let lastPush = Calendar.current.date(byAdding: .hour, value: -24, to: Date())!

        let canSend = EngagementStateManager.canSendPush(
            pushesSent30Days: 1,
            lastPushDate: lastPush,
            now: Date()
        )

        XCTAssertFalse(canSend, "Should NOT send push within 48 hours of last push")
    }

    func testCanSendPushAfter48Hours() {
        let lastPush = Calendar.current.date(byAdding: .hour, value: -49, to: Date())!

        let canSend = EngagementStateManager.canSendPush(
            pushesSent30Days: 1,
            lastPushDate: lastPush,
            now: Date()
        )

        XCTAssertTrue(canSend, "Should allow push after 48 hours have passed")
    }

    func testCanSendPushWhenNoPreviousPush() {
        let canSend = EngagementStateManager.canSendPush(
            pushesSent30Days: 0,
            lastPushDate: nil,
            now: Date()
        )

        XCTAssertTrue(canSend, "Should allow first push when no previous pushes")
    }

    // MARK: - Push Safeguards: No Push After Churned

    func testNoPushForChurnedState() {
        let canSend = EngagementStateManager.shouldSendPush(forState: .churned)

        XCTAssertFalse(canSend, "Should NEVER send push to churned users")
    }

    func testPushAllowedForDriftingState() {
        let canSend = EngagementStateManager.shouldSendPush(forState: .drifting)

        XCTAssertTrue(canSend)
    }

    func testPushAllowedForLapsedState() {
        let canSend = EngagementStateManager.shouldSendPush(forState: .lapsed)

        XCTAssertTrue(canSend)
    }

    func testNoPushForEngagedState() {
        let canSend = EngagementStateManager.shouldSendPush(forState: .engaged)

        XCTAssertFalse(canSend, "Engaged users don't need re-engagement pushes")
    }

    // MARK: - State Enum

    func testAllStatesExist() {
        let states: [EngagementStateManager.EngagementState] = [
            .engaged, .atRisk, .drifting, .lapsed, .churned
        ]
        XCTAssertEqual(states.count, 5)
    }

    // MARK: - Days Since Last Open Calculation

    func testDaysSinceLastOpenCalculation() {
        let lastOpen = Calendar.current.date(byAdding: .day, value: -3, to: Date())!

        let days = EngagementStateManager.daysSinceLastOpen(from: lastOpen, to: Date())

        XCTAssertEqual(days, 3)
    }

    func testDaysSinceLastOpenReturnsZeroForToday() {
        let lastOpen = Date()

        let days = EngagementStateManager.daysSinceLastOpen(from: lastOpen, to: Date())

        XCTAssertEqual(days, 0)
    }
}
