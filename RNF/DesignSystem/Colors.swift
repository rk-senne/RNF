import SwiftUI

struct RNFColors {
    // MARK: - Brand
    static let primary = Color(hex: "#7C3AED")
    static let primaryLight = Color(hex: "#9B6BF7")

    // MARK: - Status
    static let success = Color(hex: "#22A559")
    static let warning = Color(hex: "#D4940F")
    static let destructive = Color(hex: "#DC2626")

    // MARK: - Surfaces (adaptive)
    static let surface = Color(.secondarySystemBackground)
    static let surfaceElevated = Color(.tertiarySystemBackground)
    static let surfacePressed = Color(.quaternarySystemFill)

    // MARK: - Legacy (kept for compatibility)
    static let backgroundLight = Color(hex: "#F4F5F7")
    static let backgroundDark = Color(hex: "#121212")
    static let secondaryText = Color(hex: "#6B7280")

    // MARK: - Text (adaptive)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)

    // MARK: - Borders (adaptive)
    static let border = Color(.separator)
    static let borderSubtle = Color(.separator).opacity(0.5)

    // MARK: - Tints
    static let streak = Color(red: 0.9, green: 0.46, blue: 0.18)
    static let quest = Color(red: 0.3, green: 0.43, blue: 0.86)
    static let reading = Color(red: 0.73, green: 0.36, blue: 0.18)

    // MARK: - Stats
    static let statStrength = Color(hex: "#D4940F")
    static let statDiscipline = Color(hex: "#7C3AED")
    static let statFocus = Color(hex: "#2563EB")
    static let statEnergy = Color(hex: "#DC2626")
    static let statWisdom = Color(hex: "#059669")
    static let statMind = Color(hex: "#7C3AED")
    static let statSpirit = Color(hex: "#8B5CF6")
}
