import Foundation
import Supabase
import os

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

        RNFLogger.auth.info("Sign-up initiated")
        let response = try await supabase.client.auth.signUp(
            email: email,
            password: password
        )

        let result = signUpResult(from: response)
        try await bootstrapProfile(
            userId: result.userId,
            email: result.email ?? email
        )
        RNFLogger.auth.info("Sign-up complete")

        return result
    }

    func login(email: String, password: String) async throws -> Session {

        RNFLogger.auth.info("Login initiated")
        let session = try await supabase.client.auth.signIn(
            email: email,
            password: password
        )
        RNFLogger.auth.info("Login complete")
        return session
    }

    func logout() async throws {

        RNFLogger.auth.info("Logout initiated")
        try await supabase.client.auth.signOut()
        RNFLogger.auth.info("Logout complete")
    }

    func restoreSession() async throws -> Session {

        RNFLogger.auth.info("Restoring session")
        let session = try await supabase.client.auth.session
        RNFLogger.auth.info("Session restored")
        return session
    }

    func refreshSessionIfNeeded() async throws -> Session {
        RNFLogger.auth.info("Checking token expiry")
        let session = try await supabase.client.auth.session
        if session.expiresAt < Date().timeIntervalSince1970 + 300 {
            RNFLogger.auth.info("Token near expiry, refreshing")
            return try await supabase.client.auth.refreshSession()
        }
        return session
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
