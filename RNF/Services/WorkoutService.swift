import Foundation
import Supabase
import PostgREST

final class WorkoutService {

    private let supabase: SupabaseService
    private let dailyLogService: DailyLogService
    private let authProvider: AuthProviding

    init(
        supabase: SupabaseService = .shared,
        dailyLogService: DailyLogService = DailyLogService(),
        authProvider: AuthProviding? = nil
    ) {
        self.supabase = supabase
        self.dailyLogService = dailyLogService
        self.authProvider = authProvider ?? AuthService(supabase: supabase)
    }

    func dailyLogForWorkout(userId: UUID, date: Date = Date()) async throws -> DailyLog {
        if let dailyLog = try await dailyLogService.fetchTodayLog(userId: userId, date: date) {
            return dailyLog
        }

        return try await dailyLogService.createDailyLog(userId: userId, date: date)
    }

    func dailyLogForWorkout(date: Date = Date()) async throws -> DailyLog {
        let userId = try await authProvider.requireCurrentUserID()
        return try await dailyLogForWorkout(userId: userId, date: date)
    }

    func completeWorkout(userId: UUID, date: Date = Date()) async throws -> DailyLog {
        let dailyLog = try await dailyLogForWorkout(userId: userId, date: date)

        struct WorkoutCompletionUpdate: Encodable {
            let workout_completed: Bool
        }

        let completedLog: DailyLog = try await supabase.client
            .from("daily_logs")
            .update(WorkoutCompletionUpdate(workout_completed: true))
            .eq("id", value: dailyLog.id.uuidString)
            .select()
            .single()
            .execute()
            .value

        return try await dailyLogService.updateStatus(userId: userId, date: date) ?? completedLog
    }

    func completeWorkout(date: Date = Date()) async throws -> DailyLog {
        let userId = try await authProvider.requireCurrentUserID()
        return try await completeWorkout(userId: userId, date: date)
    }

    func startTimer(duration: TimeInterval) async {
        _ = duration
    }

    func cancelWorkout() async {}

}
