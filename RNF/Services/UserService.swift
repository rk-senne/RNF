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

    func decrementForgivenessTokens() async throws -> Int {
        let userId = try await authProvider.requireCurrentUserID()
        return try await decrementForgivenessTokens(userId: userId)
    }

    func saveProfile(_ profile: Profile) async -> RNFServiceWriteResult<Profile> {

        guard !profile.isPlaceholder else {
            return .savedLocallyOnly(profile, error: .unauthenticated)
        }

        do {
            try await supabase.client
                .from("users")
                .upsert(profile)
                .execute()

            return .savedRemotely(profile)
        } catch {
            return .savedLocallyOnly(profile, error: .from(error))
        }

    }

    func saveAuthenticatedProfile(_ profile: Profile) async -> RNFServiceWriteResult<Profile> {

        guard !profile.isPlaceholder else {
            return .savedLocallyOnly(profile, error: .unauthenticated)
        }

        do {
            _ = try await authProvider.requireCurrentUserID(matching: profile.id)
            return await saveProfile(profile)
        } catch {
            return .notSaved(.from(error))
        }

    }

}
