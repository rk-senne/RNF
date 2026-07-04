import Foundation
import Supabase

/// Supabase client wrapper. Handles missing configuration gracefully
/// with an error state instead of crashing.
final class SupabaseService {

    static let shared = SupabaseService()

    /// The Supabase client. Nil if configuration is invalid.
    let client: SupabaseClient?

    /// Error message when initialization fails.
    let configurationError: String?

    private init() {
        guard let urlString = AppConfig.supabaseURL,
              let url = URL(string: urlString),
              url.host != nil,
              url.scheme == "https" else {
            self.client = nil
            self.configurationError = "Invalid or missing Supabase URL in AppConfig"
            RNFLogger.auth.error("SupabaseService: \(self.configurationError ?? "unknown error")")
            return
        }

        guard let anonKey = AppConfig.supabaseAnonKey else {
            self.client = nil
            self.configurationError = "Missing Supabase anon key in AppConfig"
            RNFLogger.auth.error("SupabaseService: \(self.configurationError ?? "unknown error")")
            return
        }

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey
        )
        self.configurationError = nil
    }

    /// Test-friendly initializer with pre-configured client.
    init(client: SupabaseClient) {
        self.client = client
        self.configurationError = nil
    }

    /// Whether the service is properly configured and ready.
    var isConfigured: Bool {
        client != nil
    }

    /// Convenience non-optional accessor for service code.
    /// All call sites already use `try await supabase.db.from(...)` so the
    /// throwing getter is transparent.
    var db: SupabaseClient {
        get throws {
            guard let client else {
                throw SupabaseServiceError.notConfigured(configurationError ?? "Supabase not configured")
            }
            return client
        }
    }
}

enum SupabaseServiceError: LocalizedError {
    case notConfigured(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured(let reason):
            return "Supabase not configured: \(reason)"
        }
    }
}
