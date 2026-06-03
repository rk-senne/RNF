import Foundation
import Supabase
import PostgREST

final class UserService {

    private struct ForgivenessTokenRow: Decodable {
        let forgiveness_tokens: Int
    }

    private struct ForgivenessTokenUpdate: Encodable {
        let forgiveness_tokens: Int
    }

    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func loadProfile() async -> Profile {

        do {
            let profiles: [Profile] = try await supabase.client
                .from("users")
                .select()
                .limit(1)
                .execute()
                .value

            return profiles.first ?? .placeholder
        } catch {
            return .placeholder
        }

    }

    func fetchForgivenessTokens(userId: UUID) async throws -> Int {

        let rows: [ForgivenessTokenRow] = try await supabase.client
            .from("users")
            .select("forgiveness_tokens")
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return rows.first?.forgiveness_tokens ?? 0
    }

    func decrementForgivenessTokens(userId: UUID) async throws -> Int {

        let currentTokens = try await fetchForgivenessTokens(userId: userId)

        guard currentTokens > 0 else {
            return 0
        }

        let updatedTokens = currentTokens - 1
        let updatedRow: ForgivenessTokenRow = try await supabase.client
            .from("users")
            .update(ForgivenessTokenUpdate(forgiveness_tokens: updatedTokens))
            .eq("id", value: userId.uuidString)
            .select("forgiveness_tokens")
            .single()
            .execute()
            .value

        return updatedRow.forgiveness_tokens
    }

    func saveProfile(_ profile: Profile) async {

        guard !profile.isPlaceholder else {
            return
        }

        do {
            try await supabase.client
                .from("users")
                .upsert(profile)
                .execute()
        } catch {
            // The local game state remains authoritative until auth is added.
        }

    }

}
