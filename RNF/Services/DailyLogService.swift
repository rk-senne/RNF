import Foundation
import Supabase
import PostgREST

final class DailyLogService {

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

    private func normalizedDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    func fetchTodayLog(userId: UUID, date: Date) async throws -> DailyLog? {

        let normalizedDate = normalizedDay(date)

        let logs: [DailyLog] = try await supabase.client
            .from("daily_logs")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: normalizedDate)
            .limit(1)
            .execute()
            .value

        return logs.first
    }

    func createDailyLog(userId: UUID, date: Date) async throws -> DailyLog {

        let normalizedDate = normalizedDay(date)

        let dailyLog = DailyLog(
            id: UUID(),
            user_id: userId,
            date: normalizedDate,
            habits_completed: 0,
            habits_required: 2,
            workout_completed: false,
            reading_completed: false,
            forgiveness_used: false,
            xp_earned: 0,
            status: .partial,
            created_at: nil
        )

        do {
            let createdLog: DailyLog = try await supabase.client
                .from("daily_logs")
                .insert(dailyLog)
                .select()
                .single()
                .execute()
                .value

            return createdLog
        } catch {
            if let existingLog = try await fetchTodayLog(userId: userId, date: normalizedDate) {
                return existingLog
            }

            throw error
        }
    }

    func getTodayLog(for profile: Profile, dailyGoal: Int) async throws -> DailyLog {

        guard !profile.isPlaceholder else {
            return .today(goal: dailyGoal)
        }

        let today = normalizedDay(Date())

        if let log = try await fetchTodayLog(
            userId: profile.id,
            date: today
        ) {
            return log
        }

        return try await createDailyLog(
            userId: profile.id,
            date: today
        )
    }

    func recordCompletion(_ completion: HabitCompletion) async {
        await habitService.recordCompletion(completion)
    }

    func recordHabitCompletion(_ completion: HabitCompletion) async throws -> HabitCompletion? {

        guard let userId = completion.user_id else {
            return nil
        }

        let normalizedDate = normalizedDay(completion.date)

        let completions: [HabitCompletion] = try await supabase.client
            .from("habit_completions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("habit_id", value: completion.habit_id.uuidString)
            .eq("date", value: normalizedDate)
            .limit(1)
            .execute()
            .value

        if let existingCompletion = completions.first {
            return existingCompletion
        }

        let normalizedCompletion = HabitCompletion(
            id: completion.id,
            user_id: completion.user_id,
            habit_id: completion.habit_id,
            completed_at: completion.completed_at,
            date: normalizedDate,
            xp_awarded: completion.xp_awarded,
            created_at: completion.created_at
        )

        let createdCompletion: HabitCompletion = try await supabase.client
            .from("habit_completions")
            .insert(normalizedCompletion)
            .select()
            .single()
            .execute()
            .value

        return createdCompletion
    }

    func calculateStatus(for dailyLog: DailyLog) -> DailyLog.Status {

        if dailyLog.habits_completed == dailyLog.habits_required &&
            dailyLog.workout_completed &&
            dailyLog.reading_completed {
            return .complete
        }

        if dailyLog.habits_completed > 0 {
            return .partial
        }

        return .missed
    }

    func saveDailyLog(_ dailyLog: DailyLog) async {

        guard dailyLog.user_id != nil else {
            return
        }

        let normalizedDailyLog = DailyLog(
            id: dailyLog.id,
            user_id: dailyLog.user_id,
            date: normalizedDay(dailyLog.date),
            habits_completed: dailyLog.habits_completed,
            habits_required: dailyLog.habits_required,
            workout_completed: dailyLog.workout_completed,
            reading_completed: dailyLog.reading_completed,
            forgiveness_used: dailyLog.forgiveness_used,
            xp_earned: dailyLog.xp_earned,
            status: dailyLog.status,
            created_at: dailyLog.created_at
        )

        do {
            try await supabase.client
                .from("daily_logs")
                .upsert(normalizedDailyLog)
                .execute()
        } catch {
            // Local state stays consistent even if the backend call fails.
        }

    }

    func saveProfile(_ profile: Profile) async {
        await userService.saveProfile(profile)
    }

}
