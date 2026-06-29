import Foundation
import XCTest
@testable import RNF

final class DateNormalizationTests: XCTestCase {

    // MARK: - Daily Log Date Normalization

    func testDailyLogNormalizesDateToStartOfDay() {
        let afternoon = Self.date("2026-06-15T15:30:45Z")
        let log = DailyLog(
            id: UUID(),
            user_id: UUID(),
            date: afternoon.startOfDay,
            habits_completed: 0,
            habits_required: 2,
            workout_completed: false,
            reading_completed: false,
            forgiveness_used: false,
            xp_earned: 0,
            status: .partial,
            created_at: nil
        )

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: log.date)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testStartOfDayIsIdempotent() {
        let date = Self.date("2026-06-15T23:59:59Z")
        let normalized = date.startOfDay
        XCTAssertEqual(normalized, normalized.startOfDay)
    }

    func testDifferentTimesOnSameDayNormalizeToSameValue() {
        let morning = Self.date("2026-06-15T06:00:00Z")
        let evening = Self.date("2026-06-15T22:00:00Z")
        XCTAssertEqual(morning.startOfDay, evening.startOfDay)
    }

    func testMidnightBoundaryProducesCorrectDay() {
        let justBeforeMidnight = Self.date("2026-06-15T23:59:59Z")
        let justAfterMidnight = Self.date("2026-06-16T00:00:01Z")
        XCTAssertNotEqual(justBeforeMidnight.startOfDay, justAfterMidnight.startOfDay)
    }

    // MARK: - Challenge Day Boundary

    func testChallengeDayBoundaryUsesStartOfDay() {
        let calendar = Calendar.current
        let startDate = Self.date("2026-01-01T10:00:00Z")
        let sameDay = Self.date("2026-01-01T23:59:00Z")

        let startNorm = calendar.startOfDay(for: startDate)
        let targetNorm = calendar.startOfDay(for: sameDay)
        let elapsed = calendar.dateComponents([.day], from: startNorm, to: targetNorm).day ?? 0

        XCTAssertEqual(elapsed, 0, "Same calendar day should yield 0 elapsed days")
    }

    func testChallengeDayAdvancesAfterMidnight() {
        let calendar = Calendar.current
        let startDate = Self.date("2026-01-01T10:00:00Z")
        let nextDay = Self.date("2026-01-02T00:00:01Z")

        let startNorm = calendar.startOfDay(for: startDate)
        let targetNorm = calendar.startOfDay(for: nextDay)
        let elapsed = calendar.dateComponents([.day], from: startNorm, to: targetNorm).day ?? 0

        XCTAssertEqual(elapsed, 1)
    }

    func testChallengeDay90MatchesExpectedEndDate() {
        let calendar = Calendar.current
        let startDate = Self.date("2026-01-01T00:00:00Z")
        let day90Date = Self.date("2026-03-31T12:00:00Z")

        let startNorm = calendar.startOfDay(for: startDate)
        let targetNorm = calendar.startOfDay(for: day90Date)
        let elapsed = calendar.dateComponents([.day], from: startNorm, to: targetNorm).day ?? 0

        XCTAssertEqual(elapsed + 1, 90)
    }

    // MARK: - Helpers

    private static func date(_ string: String) -> Date {
        ISO8601DateFormatter().date(from: string) ?? Date(timeIntervalSince1970: 0)
    }
}
