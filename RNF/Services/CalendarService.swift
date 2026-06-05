import Foundation
import Supabase
import PostgREST

final class CalendarService {

    private let supabase: SupabaseService
    private let authProvider: AuthProviding
    private let calendar: Calendar

    init(
        supabase: SupabaseService = .shared,
        authProvider: AuthProviding? = nil,
        calendar: Calendar = .current
    ) {
        self.supabase = supabase
        self.authProvider = authProvider ?? AuthService(supabase: supabase)
        self.calendar = calendar
    }

    private func normalizedDay(_ date: Date) -> Date {
        DayBoundaryPolicy.normalizedDay(for: date, calendar: calendar)
    }

    func getMonthLogs(userId: UUID, month: Date) async throws -> [DailyLog] {

        let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: month)
        ) ?? DayBoundaryPolicy.normalizedDay(for: month, calendar: calendar)
        let startOfNextMonth = calendar.date(
            byAdding: .month,
            value: 1,
            to: startOfMonth
        ) ?? startOfMonth

        let logs: [DailyLog] = try await supabase.client
            .from("daily_logs")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("date", value: startOfMonth)
            .lt("date", value: startOfNextMonth)
            .order("date", ascending: true)
            .execute()
            .value

        return logs
    }

    func getMonthLogs(month: Date) async throws -> [DailyLog] {
        let userId = try await authProvider.requireCurrentUserID()
        return try await getMonthLogs(userId: userId, month: month)
    }

    func groupMonthLogsByDay(_ logs: [DailyLog]) -> [Date: DailyLog] {
        logs.reduce(into: [:]) { groupedLogs, dailyLog in
            groupedLogs[normalizedDay(dailyLog.date)] = dailyLog
        }
    }

    func calendarStatus(for date: Date, logsByDay: [Date: DailyLog]) -> DailyLogStatus {
        guard let dailyLog = logsByDay[normalizedDay(date)] else {
            return .missed
        }

        return mapLogToCalendarStatus(dailyLog)
    }

    func mapLogToCalendarStatus(_ dailyLog: DailyLog) -> DailyLogStatus {
        DailyLogStatus(rawValue: dailyLog.status.rawValue) ?? .missed
    }

}
