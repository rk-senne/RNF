import XCTest
@testable import RNF

final class PassiveDiscoverySystemTests: XCTestCase {

    private func makeHistory(_ ids: [String]) -> [DiscoveryRecord] {
        ids.map { DiscoveryRecord(discoveryID: $0, earnedDate: "2026-01-01") }
    }

    func testBeforeDawnTriggersWhenHourBefore6() {
        let results = PassiveDiscoverySystem.evaluate(
            steps: 0, streak: 0, totalHabits: 0, level: 1,
            stats: [], hour: 4, daysSinceStart: 0, isWeekend: false, history: []
        )
        XCTAssertTrue(results.contains(where: { $0.id == "before_dawn" }))
    }

    func testLateForgeTriggersAt23() {
        let results = PassiveDiscoverySystem.evaluate(
            steps: 0, streak: 0, totalHabits: 0, level: 1,
            stats: [], hour: 23, daysSinceStart: 0, isWeekend: false, history: []
        )
        XCTAssertTrue(results.contains(where: { $0.id == "late_forge" }))
    }

    func testPerfectWeekRequiresMultipleOf7() {
        let results = PassiveDiscoverySystem.evaluate(
            steps: 0, streak: 14, totalHabits: 0, level: 1,
            stats: [], hour: 12, daysSinceStart: 14, isWeekend: false, history: []
        )
        XCTAssertTrue(results.contains(where: { $0.id == "perfect_week" }))
    }

    func testAlreadyEarnedDiscoveryNotReturned() {
        let history = makeHistory(["before_dawn"])
        let results = PassiveDiscoverySystem.evaluate(
            steps: 0, streak: 0, totalHabits: 0, level: 1,
            stats: [], hour: 4, daysSinceStart: 0, isWeekend: false, history: history
        )
        XCTAssertFalse(results.contains(where: { $0.id == "before_dawn" }))
    }

    func testBalancedRequiresAllStatsAbove10() {
        let results = PassiveDiscoverySystem.evaluate(
            steps: 0, streak: 0, totalHabits: 0, level: 1,
            stats: [11, 12, 15, 11, 13], hour: 12, daysSinceStart: 0, isWeekend: false, history: []
        )
        XCTAssertTrue(results.contains(where: { $0.id == "balanced" }))

        let noBalanced = PassiveDiscoverySystem.evaluate(
            steps: 0, streak: 0, totalHabits: 0, level: 1,
            stats: [11, 12, 5, 11, 13], hour: 12, daysSinceStart: 0, isWeekend: false, history: []
        )
        XCTAssertFalse(noBalanced.contains(where: { $0.id == "balanced" }))
    }

    func testTheReturnRequiresStreak1AndDaysOver7() {
        let results = PassiveDiscoverySystem.evaluate(
            steps: 0, streak: 1, totalHabits: 0, level: 1,
            stats: [], hour: 12, daysSinceStart: 10, isWeekend: false, history: []
        )
        XCTAssertTrue(results.contains(where: { $0.id == "the_return" }))
    }

    func testWalkerTriggersAt5000Steps() {
        let results = PassiveDiscoverySystem.evaluate(
            steps: 5000, streak: 0, totalHabits: 0, level: 1,
            stats: [], hour: 12, daysSinceStart: 0, isWeekend: false, history: []
        )
        XCTAssertTrue(results.contains(where: { $0.id == "the_walker" }))
    }

    func testNoRestDaysRequiresWeekend() {
        let weekday = PassiveDiscoverySystem.evaluate(
            steps: 3000, streak: 0, totalHabits: 0, level: 1,
            stats: [], hour: 12, daysSinceStart: 0, isWeekend: false, history: []
        )
        XCTAssertFalse(weekday.contains(where: { $0.id == "no_rest_days" }))

        let weekend = PassiveDiscoverySystem.evaluate(
            steps: 3000, streak: 0, totalHabits: 0, level: 1,
            stats: [], hour: 12, daysSinceStart: 0, isWeekend: true, history: []
        )
        XCTAssertTrue(weekend.contains(where: { $0.id == "no_rest_days" }))
    }

    func testSeekerRequires10InHistory() {
        let history = makeHistory((1...10).map { "disc_\($0)" })
        let results = PassiveDiscoverySystem.evaluate(
            steps: 0, streak: 0, totalHabits: 0, level: 1,
            stats: [], hour: 12, daysSinceStart: 0, isWeekend: false, history: history
        )
        XCTAssertTrue(results.contains(where: { $0.id == "seeker" }))
    }
}
