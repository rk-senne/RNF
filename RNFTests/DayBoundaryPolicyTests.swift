import Foundation
import XCTest
@testable import RNF

final class DayBoundaryPolicyTests: XCTestCase {

    func testNormalizedDayAndIdentifierUseInjectedCalendar() throws {
        let date = try XCTUnwrap(Self.date("2026-03-10T22:30:00Z"))
        let calendar = Self.calendar(timeZoneOffset: 7_200)

        let normalizedDay = DayBoundaryPolicy.normalizedDay(
            for: date,
            calendar: calendar
        )
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: normalizedDay
        )

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 11)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
        XCTAssertEqual(
            DayBoundaryPolicy.dayIdentifier(for: date, calendar: calendar),
            "2026-03-11"
        )
    }

    private static func calendar(timeZoneOffset: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: timeZoneOffset) ?? .current
        return calendar
    }

    private static func date(_ string: String) -> Date? {
        ISO8601DateFormatter().date(from: string)
    }

}
