import Foundation

final class HealthImportService {

    enum HealthImportError: Error {
        case durationTooShort
    }

    private let supabase: SupabaseService
    private let workoutService: WorkoutService

    init(supabase: SupabaseService = .shared, workoutService: WorkoutService = WorkoutService()) {
        self.supabase = supabase
        self.workoutService = workoutService
    }

    struct HealthImportRecord: Codable {
        let id: UUID
        let user_id: UUID
        let healthkit_uuid: String
        let workout_type: String
        let start_date: Date
        let end_date: Date
        let duration_seconds: Int
        let active_energy: Double?
        let accepted: Bool
        let created_at: Date?
    }

    /// Returns true if this HealthKit workout has already been imported.
    func isAlreadyImported(userId: UUID, healthKitUUID: String) async throws -> Bool {
        let records: [HealthImportRecord] = try await supabase.client
            .from("health_imports")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("healthkit_uuid", value: healthKitUUID)
            .limit(1)
            .execute()
            .value
        return !records.isEmpty
    }

    /// Accept a HealthKit workout and credit it toward the daily log.
    /// Chaos #7: Requires minimum 60 seconds duration for consistency with in-app timer flow.
    func acceptWorkout(userId: UUID, summary: HealthWorkoutSummary, date: Date = Date()) async throws -> HealthImportRecord {
        guard summary.durationSeconds >= 60 else {
            throw HealthImportError.durationTooShort
        }

        let record = HealthImportRecord(
            id: UUID(), user_id: userId,
            healthkit_uuid: summary.healthKitUUID,
            workout_type: summary.workoutType,
            start_date: summary.startDate,
            end_date: summary.endDate,
            duration_seconds: summary.durationSeconds,
            active_energy: summary.activeEnergyBurned,
            accepted: true,
            created_at: nil
        )

        let created: HealthImportRecord = try await supabase.client
            .from("health_imports")
            .insert(record)
            .select()
            .single()
            .execute()
            .value

        // Credit the daily log
        _ = try await workoutService.completeWorkout(userId: userId, date: date)

        return created
    }
}
