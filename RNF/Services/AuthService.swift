import Foundation
import Supabase

struct SignUpResult {
    let session: Session?
    let userId: UUID
    let email: String?
}

final class AuthService {

    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func signUp(email: String, password: String) async throws -> SignUpResult {

        let response = try await supabase.client.auth.signUp(
            email: email,
            password: password
        )

        let result = signUpResult(from: response)
        try await bootstrapProfile(
            userId: result.userId,
            email: result.email ?? email
        )

        return result
    }

    func login(email: String, password: String) async throws -> Session {

        try await supabase.client.auth.signIn(
            email: email,
            password: password
        )
    }

    func logout() async throws {

        try await supabase.client.auth.signOut()
    }

    func restoreSession() async throws -> Session {

        try await supabase.client.auth.session
    }

    private func signUpResult(from response: AuthResponse) -> SignUpResult {

        switch response {
        case .session(let session):
            return SignUpResult(
                session: session,
                userId: session.user.id,
                email: session.user.email
            )
        case .user(let user):
            return SignUpResult(
                session: nil,
                userId: user.id,
                email: user.email
            )
        }
    }

    private func makeBootstrapProfile(userId: UUID, email: String?) -> Profile {

        Profile(
            id: userId,
            email: email,
            xp_total: 0,
            level: 1,
            streak: 0,
            forgiveness_tokens: 0,
            morning_notification_time: nil,
            evening_notification_time: nil,
            strength: Stats.baseline.strength,
            discipline: Stats.baseline.discipline,
            focus: Stats.baseline.focus,
            energy: Stats.baseline.energy,
            wisdom: Stats.baseline.wisdom,
            mind: Stats.baseline.mind,
            spirit: Stats.baseline.spirit,
            created_at: nil
        )
    }

    private func bootstrapProfile(userId: UUID, email: String?) async throws {

        try await supabase.client
            .from("users")
            .upsert(makeBootstrapProfile(userId: userId, email: email))
            .execute()
    }

}
