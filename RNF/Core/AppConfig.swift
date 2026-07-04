import Foundation
import os

/// App configuration loaded from Info.plist.
/// Returns nil instead of crashing when keys are missing, allowing graceful degradation.
enum AppConfig {

    private static let logger = Logger(subsystem: "com.rnf.app", category: "AppConfig")

    /// Supabase project URL. Returns nil if not configured.
    static var supabaseURL: String? {
        guard let url = Bundle.main.object(
            forInfoDictionaryKey: "SUPABASE_URL"
        ) as? String, !url.isEmpty, url != "$(SUPABASE_URL)" else {
            logger.error("SUPABASE_URL missing or placeholder in Info.plist")
            return nil
        }
        return url
    }

    /// Supabase anonymous API key. Returns nil if not configured.
    static var supabaseAnonKey: String? {
        guard let key = Bundle.main.object(
            forInfoDictionaryKey: "SUPABASE_ANON_KEY"
        ) as? String, !key.isEmpty, key != "$(SUPABASE_ANON_KEY)" else {
            logger.error("SUPABASE_ANON_KEY missing or placeholder in Info.plist")
            return nil
        }
        return key
    }

    /// Runtime validation — true if all required config is present.
    static var isValid: Bool {
        supabaseURL != nil && supabaseAnonKey != nil
    }
}
