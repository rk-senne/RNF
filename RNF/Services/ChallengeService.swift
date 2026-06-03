import Foundation
import Supabase
import PostgREST

final class ChallengeService {

    private let supabase: SupabaseService
    private let analyticsService: AnalyticsService
    private let authProvider: AuthProviding

    init(
        supabase: SupabaseService = .shared,
        analyticsService: AnalyticsService = AnalyticsService(),
        authProvider: AuthProviding? = nil
    ) {
        self.supabase = supabase
        self.analyticsService = analyticsService
        self.authProvider = authProvider ?? AuthService(supabase: supabase)
    }

    private func normalizedDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    func startChallenge(userId: UUID, startDate: Date = Date()) async throws -> Challenge {

        let normalizedStartDate = normalizedDay(startDate)
        let endDate = Calendar.current.date(
            byAdding: .day,
            value: 89,
            to: normalizedStartDate
        ) ?? normalizedStartDate

        let challenge = Challenge(
            id: UUID(),
            user_id: userId,
            start_date: normalizedStartDate,
            end_date: endDate,
            current_day: 1,
            status: .active,
            created_at: nil
        )

        let createdChallenge: Challenge = try await supabase.client
            .from("challenges")
            .insert(challenge)
            .select()
            .single()
            .execute()
            .value

        await analyticsService.trackEvent(
            .challengeStarted,
            properties: [
                "user_id": userId.uuidString,
                "start_date": Self.analyticsTimestamp(for: normalizedStartDate)
            ]
        )

        return createdChallenge
    }

    func startChallenge(startDate: Date = Date()) async throws -> Challenge {
        let userId = try await authProvider.requireCurrentUserID()
        return try await startChallenge(userId: userId, startDate: startDate)
    }

    func getActiveChallenge(userId: UUID) async throws -> Challenge? {

        let challenges: [Challenge] = try await supabase.client
            .from("challenges")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: Challenge.Status.active.rawValue)
            .limit(1)
            .execute()
            .value

        return challenges.first
    }

    func getActiveChallenge() async throws -> Challenge? {
        let userId = try await authProvider.requireCurrentUserID()
        return try await getActiveChallenge(userId: userId)
    }

    func advanceDay(_ challenge: Challenge) async throws -> Challenge {

        let advancedChallenge = challenge.mapped(
            currentDay: min(challenge.normalizedCurrentDay + 1, Challenge.totalDays)
        )

        struct DayUpdate: Encodable {
            let current_day: Int
        }

        let updatedChallenge: Challenge = try await supabase.client
            .from("challenges")
            .update(DayUpdate(current_day: advancedChallenge.current_day))
            .eq("id", value: challenge.id.uuidString)
            .select()
            .single()
            .execute()
            .value

        return updatedChallenge
    }

    func completeChallenge(challengeId: UUID) async throws -> Challenge {

        struct StatusUpdate: Encodable {
            let status: Challenge.Status
        }

        let completedChallenge: Challenge = try await supabase.client
            .from("challenges")
            .update(StatusUpdate(status: .completed))
            .eq("id", value: challengeId.uuidString)
            .select()
            .single()
            .execute()
            .value

        await analyticsService.trackEvent(
            .challengeCompleted,
            properties: [
                "user_id": completedChallenge.user_id.uuidString,
                "end_date": Self.analyticsTimestamp(for: completedChallenge.end_date)
            ]
        )

        return completedChallenge
    }

    func restartChallenge(
        _ challenge: Challenge,
        startDate: Date = Date()
    ) async throws -> Challenge {

        struct StatusUpdate: Encodable {
            let status: Challenge.Status
        }

        try await supabase.client
            .from("challenges")
            .update(StatusUpdate(status: .reset))
            .eq("id", value: challenge.id.uuidString)
            .execute()

        return try await startChallenge(
            userId: challenge.user_id,
            startDate: startDate
        )
    }

    private static func analyticsTimestamp(for date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

}
