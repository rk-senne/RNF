import Foundation

// P22-ONB-03: Transfer anonymous progress to authenticated profile on signup.
@MainActor
final class GuestDataMigrationService: ObservableObject {

    // MARK: - State

    @Published var isMigrating = false
    @Published var migrationComplete = false
    @Published var migrationError: String?

    // MARK: - Dependencies

    private let guestSession: GuestSessionManager
    private let supabase: SupabaseService
    private let authProvider: AuthProviding

    // MARK: - Init

    init(
        guestSession: GuestSessionManager,
        supabase: SupabaseService = .shared,
        authProvider: AuthProviding? = nil
    ) {
        self.guestSession = guestSession
        self.supabase = supabase
        self.authProvider = authProvider ?? AuthService(supabase: supabase)
    }

    // MARK: - Migration

    func migrateGuestData() async {
        guard let sessionData = guestSession.sessionData else {
            RNFLogger.auth.info("No guest session data to migrate")
            migrationComplete = true
            return
        }

        guard sessionData.xp > 0 else {
            cleanupAndComplete()
            return
        }

        isMigrating = true
        migrationError = nil

        do {
            let userId = try await authProvider.requireCurrentUserID()
            try await applyXPToProfile(userId: userId, xp: sessionData.xp)
            try await recordMigratedHabits(userId: userId, habitIDs: sessionData.completedHabitIDs)

            cleanupAndComplete()
            RNFLogger.auth.info("Guest data migration complete: \(sessionData.xp) XP transferred")
        } catch {
            RNFLogger.auth.error("Guest data migration failed: \(error.localizedDescription)")
            migrationError = "Could not transfer your progress. You can try again later."
            isMigrating = false
        }
    }

    // MARK: - Private

    private func applyXPToProfile(userId: UUID, xp: Int) async throws {
        guard let client = supabase.client else {
            throw MigrationError.serviceUnavailable
        }

        let profiles: [ProfileXPRow] = try await client
            .from("users")
            .select("xp_total")
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        let currentXP = profiles.first?.xp_total ?? 0
        let newXP = currentXP + xp
        let newLevel = XPSystem.levelState(for: newXP).level

        try await client
            .from("users")
            .update(ProfileXPUpdate(xp_total: newXP, level: newLevel))
            .eq("id", value: userId.uuidString)
            .execute()
    }

    private func recordMigratedHabits(userId: UUID, habitIDs: Set<String>) async throws {
        guard !habitIDs.isEmpty, let client = supabase.client else { return }

        let rows = habitIDs.map { habitID in
            MigratedHabitRow(
                user_id: userId.uuidString,
                habit_id: habitID,
                source: "guest_session",
                completed_at: ISO8601DateFormatter().string(from: Date())
            )
        }

        try await client
            .from("habit_completions")
            .insert(rows)
            .execute()
    }

    private func cleanupAndComplete() {
        guestSession.endSession()
        isMigrating = false
        migrationComplete = true
    }
}

// MARK: - Supporting Types

private extension GuestDataMigrationService {

    struct ProfileXPRow: Decodable {
        let xp_total: Int
    }

    struct ProfileXPUpdate: Encodable {
        let xp_total: Int
        let level: Int
    }

    struct MigratedHabitRow: Encodable {
        let user_id: String
        let habit_id: String
        let source: String
        let completed_at: String
    }

    enum MigrationError: LocalizedError {
        case serviceUnavailable

        var errorDescription: String? {
            switch self {
            case .serviceUnavailable:
                return "Service unavailable. Please try again later."
            }
        }
    }
}
