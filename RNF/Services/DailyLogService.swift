import Foundation
import Supabase
import PostgREST

final class DailyLogService {

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let supabase: SupabaseService
    private let habitService: HabitService
    private let userService: UserService

    init(
        supabase: SupabaseService = .shared,
        habitService: HabitService = HabitService(),
        userService: UserService = UserService()
    ) {
        self.supabase = supabase
        self.habitService = habitService
        self.userService = userService
    }

    func fetchTodayLog(userId: UUID, date: Date) async throws -> DailyLog? {

        let dayString = Self.dayFormatter.string(from: date.startOfDay)

        let logs: [DailyLog] = try await supabase.client
            .from("daily_logs")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: dayString)
            .limit(1)
            .execute()
            .value

        return logs.first
    }

    func createDailyLog(userId: UUID, date: Date) async throws -> DailyLog {

        let dailyLog = DailyLog(
            id: UUID(),
            user_id: userId,
            date: date.startOfDay,
            habits_completed: 0,
            habits_required: 2,
            workout_completed: false,
            reading_completed: false,
            forgiveness_used: false,
            xp_earned: 0,
            status: .partial,
            created_at: nil
        )

        let createdLog: DailyLog = try await supabase.client
            .from("daily_logs")
            .insert(dailyLog)
            .select()
            .single()
            .execute()
            .value

        return createdLog
    }

    func getTodayLog(for profile: Profile, dailyGoal: Int) async -> DailyLog {

        guard !profile.isPlaceholder else {
            return .today(goal: dailyGoal)
        }

        do {
            if let log = try await fetchTodayLog(
                userId: profile.id,
                date: Date()
            ) {
                return log
            }
        } catch {
            // Fall back to a local daily log when the backend is unavailable.
        }

        return .today(userID: profile.id, goal: dailyGoal)
    }

    func recordCompletion(_ completion: HabitCompletion) async {
        await habitService.recordCompletion(completion)
    }

    func saveDailyLog(_ dailyLog: DailyLog) async {

        guard dailyLog.user_id != nil else {
            return
        }

        do {
            try await supabase.client
                .from("daily_logs")
                .upsert(dailyLog)
                .execute()
        } catch {
            // Local state stays consistent even if the backend call fails.
        }

    }

    func saveProfile(_ profile: Profile) async {
        await userService.saveProfile(profile)
    }

}
