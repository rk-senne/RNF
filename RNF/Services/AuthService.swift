import Foundation
import OSLog
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

        RNFLogger.auth.info("operation=sign_up result=started")

        do {
            let response = try await supabase.client.auth.signUp(
                email: email,
                password: password
            )

            let result = signUpResult(from: response)
            try await bootstrapProfile(
                userId: result.userId,
                email: result.email ?? email
            )

            RNFLogger.auth.info("operation=sign_up result=success")
            return result
        } catch {
            RNFLogger.auth.error("operation=sign_up result=failure error_category=\(RNFLogger.errorCategory(error), privacy: .public)")
            throw error
        }
    }

    func login(email: String, password: String) async throws -> Session {

        RNFLogger.auth.info("operation=login result=started")

        do {
            let session = try await supabase.client.auth.signIn(
                email: email,
                password: password
            )

            RNFLogger.auth.info("operation=login result=success")
            return session
        } catch {
            RNFLogger.auth.error("operation=login result=failure error_category=\(RNFLogger.errorCategory(error), privacy: .public)")
            throw error
        }
    }

    func logout() async throws {

        RNFLogger.auth.info("operation=logout result=started")

        do {
            try await supabase.client.auth.signOut()
            RNFLogger.auth.info("operation=logout result=success")
        } catch {
            RNFLogger.auth.error("operation=logout result=failure error_category=\(RNFLogger.errorCategory(error), privacy: .public)")
            throw error
        }
    }

    func restoreSession() async throws -> Session {

        RNFLogger.auth.info("operation=restore_session result=started")

        do {
            let session = try await supabase.client.auth.session
            RNFLogger.auth.info("operation=restore_session result=success")
            return session
        } catch {
            RNFLogger.auth.error("operation=restore_session result=failure error_category=\(RNFLogger.errorCategory(error), privacy: .public)")
            throw error
        }
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

        RNFLogger.auth.info("operation=bootstrap_profile result=started")

        do {
            try await supabase.client
                .from("users")
                .upsert(makeBootstrapProfile(userId: userId, email: email))
                .execute()

            RNFLogger.auth.info("operation=bootstrap_profile result=success")
        } catch {
            RNFLogger.auth.error("operation=bootstrap_profile result=failure error_category=\(RNFLogger.errorCategory(error), privacy: .public)")
            throw error
        }
    }

}
