import Foundation
import Supabase
import PostgREST

final class UserService {

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
