import SwiftUI

enum ThemePreference: String, CaseIterable {
    case light
    case dark
    case system

    private static let key = "rnf_theme_preference"

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    static func load() -> ThemePreference {
        guard let raw = UserDefaults.standard.string(forKey: key),
              let pref = ThemePreference(rawValue: raw)
        else { return .system }
        return pref
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: Self.key)
    }
}
