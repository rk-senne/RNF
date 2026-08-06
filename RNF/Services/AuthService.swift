import Foundation
import Supabase
import AuthenticationServices
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

    // MARK: - Email Auth

    func signUp(email: String, password: String) async throws -> SignUpResult {

        RNFLogger.auth.info("Sign-up initiated")
        guard let client = supabase.client else {
            throw AuthError.serviceUnavailable
        }
        let response = try await client.auth.signUp(
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
        guard let client = supabase.client else {
            throw AuthError.serviceUnavailable
        }
        let session = try await client.auth.signIn(
            email: email,
            password: password
        )
        RNFLogger.auth.info("Login complete")
        return session
    }

    func logout() async throws {

        RNFLogger.auth.info("Logout initiated")
        guard let client = supabase.client else {
            throw AuthError.serviceUnavailable
        }
        try await client.auth.signOut()
        RNFLogger.auth.info("Logout complete")
    }

    func restoreSession() async throws -> Session {

        RNFLogger.auth.info("Restoring session")
        guard let client = supabase.client else {
            throw AuthError.serviceUnavailable
        }
        let session = try await client.auth.session
        RNFLogger.auth.info("Session restored")
        return session
    }

    func refreshSessionIfNeeded() async throws -> Session {
        RNFLogger.auth.info("Checking token expiry")
        guard let client = supabase.client else {
            throw AuthError.serviceUnavailable
        }
        let session = try await client.auth.session
        if session.expiresAt < Date().timeIntervalSince1970 + 300 {
            RNFLogger.auth.info("Token near expiry, refreshing")
            return try await client.auth.refreshSession()
        }
        return session
    }

    // MARK: - Sign in with Apple (P21-FIX-09)

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> Session {
        RNFLogger.auth.info("Sign in with Apple initiated")
        guard let client = supabase.client else {
            throw AuthError.serviceUnavailable
        }

        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidAppleCredential
        }

        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: tokenString
            )
        )

        // Bootstrap profile if this is a new user
        let email = credential.email
        do {
            try await bootstrapProfile(userId: session.user.id, email: email)
        } catch {
            // Non-fatal: user can still proceed, profile may already exist
            RNFLogger.auth.warning("bootstrapProfile failed during Apple sign-in (may already exist): \(error.localizedDescription)")
        }

        RNFLogger.auth.info("Sign in with Apple complete")
        return session
    }

    /// Check Apple credential state for revocation detection.
    func checkAppleCredentialState(userID: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, _ in
                continuation.resume(returning: state)
            }
        }
    }

    // MARK: - Errors

    enum AuthError: Error, LocalizedError {
        case serviceUnavailable
        case invalidAppleCredential

        var errorDescription: String? {
            switch self {
            case .serviceUnavailable: return "Authentication service is unavailable"
            case .invalidAppleCredential: return "Invalid Apple credential"
            }
        }
    }

    // MARK: - Private

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

        guard let client = supabase.client else { return }
        try await client
            .from("users")
            .upsert(makeBootstrapProfile(userId: userId, email: email))
            .execute()
    }

}
