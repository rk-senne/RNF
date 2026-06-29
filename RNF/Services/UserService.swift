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
    private let authProvider: AuthProviding

    init(
        supabase: SupabaseService = .shared,
        authProvider: AuthProviding? = nil
    ) {
        self.supabase = supabase
        self.authProvider = authProvider ?? AuthService(supabase: supabase)
    }

    func loadProfile() async -> Profile {

        do {
            let userId = try await authProvider.requireCurrentUserID()
            return try await loadProfile(userId: userId) ?? .placeholder
        } catch {
            return .placeholder
        }

    }

    func loadProfile(userId: UUID) async throws -> Profile? {

        let profiles: [Profile] = try await supabase.client
            .from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return profiles.first

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

    func fetchForgivenessTokens() async throws -> Int {
        let userId = try await authProvider.requireCurrentUserID()
        return try await fetchForgivenessTokens(userId: userId)
    }

    func decrementForgivenessTokens(userId: UUID) async throws -> Int {

        // Use atomic RPC to prevent TOCTOU race condition (MEDIUM-3 / Chaos #11)
        struct RPCResult: Decodable { let use_forgiveness_token: Int }

        let result: Int = try await supabase.client
            .rpc("use_forgiveness_token", params: ["uid": userId.uuidString])
            .execute()
            .value

        // RPC returns -1 if no row was updated (tokens already 0)
        return max(result, 0)
    }

    func decrementForgivenessTokens() async throws -> Int {
        let userId = try await authProvider.requireCurrentUserID()
        return try await decrementForgivenessTokens(userId: userId)
    }

    @discardableResult
    func saveProfile(_ profile: Profile) async -> RNFServiceWriteResult<Profile> {

        guard !profile.isPlaceholder else {
            return .notSaved(.unauthenticated)
        }

        do {
            try await supabase.client
                .from("users")
                .upsert(profile)
                .execute()
            return .savedRemotely(profile)
        } catch {
            // GAP 19: Surface persistence failures.
            // Spec: RNF_PRODUCTION_READINESS_SPEC.md — "ViewModels must know whether data was saved."
            return .savedLocallyOnly(profile, error: .networkUnavailable)
        }

    }

}
