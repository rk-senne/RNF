import Foundation

enum AppConfig {

    static var supabaseURL: String {
        guard let url = Bundle.main.object(
            forInfoDictionaryKey: "SUPABASE_URL"
        ) as? String else {
            #if DEBUG
            fatalError("SUPABASE_URL missing in Info.plist")
            #else
            return ""
            #endif
        }

        return url
    }

    static var supabaseAnonKey: String {
        guard let key = Bundle.main.object(
            forInfoDictionaryKey: "SUPABASE_ANON_KEY"
        ) as? String else {
            #if DEBUG
            fatalError("SUPABASE_ANON_KEY missing in Info.plist")
            #else
            return ""
            #endif
        }

        return key
    }

}
