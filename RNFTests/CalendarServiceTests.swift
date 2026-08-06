import Foundation
import Supabase
import XCTest
@testable import RNF

@MainActor
final class CalendarServiceTests: XCTestCase {

    func testMapLogToCalendarStatusUsesDailyLogStatus() {
        let service = CalendarService(supabase: makeSupabaseService())

        XCTAssertEqual(service.mapLogToCalendarStatus(Self.dailyLog(status: .complete)), .complete)
        XCTAssertEqual(service.mapLogToCalendarStatus(Self.dailyLog(status: .partial)), .partial)
        XCTAssertEqual(service.mapLogToCalendarStatus(Self.dailyLog(status: .missed)), .missed)
        XCTAssertEqual(service.mapLogToCalendarStatus(Self.dailyLog(status: .forgiven)), .forgiven)
    }

    func testCalendarStatusUsesGroupedLogOrMissedDefault() {
        let service = CalendarService(supabase: makeSupabaseService())
        let day = Self.date("2026-06-08T14:30:00Z")
        let missingDay = Self.date("2026-06-09T00:00:00Z")
        let logsByDay = service.groupMonthLogsByDay([
            Self.dailyLog(date: day, status: .complete)
        ])

        XCTAssertEqual(service.calendarStatus(for: day, logsByDay: logsByDay), .complete)
        XCTAssertEqual(service.calendarStatus(for: missingDay, logsByDay: logsByDay), .missed)
    }

    func testGroupMonthLogsByDayNormalizesDates() {
        let service = CalendarService(supabase: makeSupabaseService())
        let calendar = Calendar.current
        let morning = Self.date("2026-06-08T08:00:00Z")
        let evening = Self.date("2026-06-08T18:00:00Z")

        let logsByDay = service.groupMonthLogsByDay([
            Self.dailyLog(date: morning, status: .partial),
            Self.dailyLog(date: evening, status: .complete)
        ])

        XCTAssertEqual(logsByDay.count, 1)
        XCTAssertEqual(
            logsByDay[calendar.startOfDay(for: morning)]?.status,
            .complete
        )
    }

    private func makeSupabaseService() -> SupabaseService {
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration)
        let options = SupabaseClientOptions(
            global: .init(session: session)
        )
        let client = SupabaseClient(
            supabaseURL: URL(string: "https://example.supabase.co")!,
            supabaseKey: "test-key",
            options: options
        )

        return SupabaseService(client: client)
    }

    private static func dailyLog(
        date: Date = Date(timeIntervalSince1970: 1_780_876_800),
        status: DailyLog.Status
    ) -> DailyLog {
        DailyLog(
            id: UUID(),
            user_id: UUID(),
            date: date,
            habits_completed: status == .complete ? 2 : 1,
            habits_required: 2,
            workout_completed: status == .complete,
            reading_completed: status == .complete,
            forgiveness_used: status == .forgiven,
            xp_earned: 0,
            status: status,
            created_at: nil
        )
    }

    private static func date(_ string: String) -> Date {
        ISO8601DateFormatter().date(from: string) ?? Date(timeIntervalSince1970: 0)
    }

}
