import Foundation
import Supabase
import PostgREST

final class CalendarService {

    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func getMonthLogs(userId: UUID, month: Date) async throws -> [DailyLog] {

        let calendar = Calendar.current
        let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: month)
        ) ?? calendar.startOfDay(for: month)
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

    func groupMonthLogsByDay(_ logs: [DailyLog]) -> [Date: DailyLog] {
        logs.reduce(into: [:]) { groupedLogs, dailyLog in
            groupedLogs[dailyLog.date.startOfDay] = dailyLog
        }
    }

    func calendarStatus(for date: Date, logsByDay: [Date: DailyLog]) -> DailyLogStatus {
        guard let dailyLog = logsByDay[date.startOfDay] else {
            return .missed
        }

        return mapLogToCalendarStatus(dailyLog)
    }

    func mapLogToCalendarStatus(_ dailyLog: DailyLog) -> DailyLogStatus {
        DailyLogStatus(rawValue: dailyLog.status.rawValue) ?? .missed
    }

}
