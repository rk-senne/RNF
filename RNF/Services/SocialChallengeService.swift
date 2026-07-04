import Foundation

final class SocialChallengeService {

    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func createChallenge(guildId: UUID, title: String, description: String?, targetCompletions: Int, startDate: Date, endDate: Date) async throws -> SocialChallenge {
        let challenge = SocialChallenge(
            id: UUID(), guild_id: guildId, title: title, description: description,
            target_completions: targetCompletions, current_completions: 0,
            status: .active, start_date: startDate, end_date: endDate, created_at: nil
        )
        let created: SocialChallenge = try await supabase.db
            .from("social_challenges").insert(challenge).select().single().execute().value
        return created
    }

    func activeChallenges(guildId: UUID) async throws -> [SocialChallenge] {
        try await supabase.db
            .from("social_challenges").select()
            .eq("guild_id", value: guildId.uuidString)
            .eq("status", value: SocialChallenge.Status.active.rawValue)
            .execute().value
    }

    func incrementProgress(challengeId: UUID) async throws -> SocialChallenge {
        let current: SocialChallenge = try await supabase.db
            .from("social_challenges").select()
            .eq("id", value: challengeId.uuidString).single().execute().value

        let newCount = current.current_completions + 1
        let newStatus: SocialChallenge.Status = newCount >= current.target_completions ? .completed : .active

        struct Update: Encodable { let current_completions: Int; let status: SocialChallenge.Status }
        let updated: SocialChallenge = try await supabase.db
            .from("social_challenges")
            .update(Update(current_completions: newCount, status: newStatus))
            .eq("id", value: challengeId.uuidString).select().single().execute().value
        return updated
    }
}
