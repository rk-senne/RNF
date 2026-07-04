import SwiftUI

// MARK: - P28-INC-01/02/03/04/05/06/07/08: Persona Theme Provider

/// Persona theme that reframes game language to suit different player identities.
/// Each persona provides themed strings for evolution tiers, streak milestones,
/// boss encounters, and accent color palettes.
enum PersonaTheme: String, Codable, CaseIterable, Identifiable {
    case warrior
    case garden
    case scholar

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .warrior: return "Warrior"
        case .garden: return "Garden"
        case .scholar: return "Scholar"
        }
    }

    var tagline: String {
        switch self {
        case .warrior: return "Forge your discipline through battle"
        case .garden: return "Nurture growth one day at a time"
        case .scholar: return "Master knowledge through daily practice"
        }
    }
}

// MARK: - ThemeProvider

@MainActor
final class ThemeProvider: ObservableObject {

    // MARK: - Singleton (convenience; inject where possible)

    static let shared = ThemeProvider()

    // MARK: - Published State

    @Published private(set) var currentTheme: PersonaTheme

    // MARK: - Persistence Key

    private static let storageKey = "rnf_persona_theme"

    // MARK: - Init

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let theme = PersonaTheme(rawValue: raw) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .warrior
        }
    }

    // MARK: - Public API

    func setTheme(_ theme: PersonaTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: Self.storageKey)
    }

    // MARK: - Evolution Tier Display Strings (P28-INC-01)

    /// Themed names for evolution tiers mapped by EvolutionRank raw values.
    var evolutionTierNames: [String: String] {
        switch currentTheme {
        case .warrior:
            return [
                "disciple": "Disciple",
                "awakened": "Awakened",
                "ascendant": "Ascendant",
                "warlord": "Warlord",
                "apex": "Apex"
            ]
        case .garden:
            return [
                "disciple": "Seedling",
                "awakened": "Sprout",
                "ascendant": "Bloom",
                "warlord": "Canopy",
                "apex": "Ancient Oak"
            ]
        case .scholar:
            return [
                "disciple": "Novice",
                "awakened": "Apprentice",
                "ascendant": "Adept",
                "warlord": "Sage",
                "apex": "Luminary"
            ]
        }
    }

    // MARK: - Streak Tier Display Strings (P28-INC-02)

    /// Themed milestone labels for streak thresholds.
    var streakTierNames: [Int: String] {
        switch currentTheme {
        case .warrior:
            return [
                3: "First Blood",
                7: "Iron Will",
                14: "Battle-Hardened",
                30: "Unbreakable",
                60: "War Machine",
                90: "Legend",
                180: "Mythic"
            ]
        case .garden:
            return [
                3: "First Leaf",
                7: "Taking Root",
                14: "In Bloom",
                30: "Flourishing",
                60: "Deep Roots",
                90: "Evergreen",
                180: "Eternal Garden"
            ]
        case .scholar:
            return [
                3: "First Lesson",
                7: "Curious Mind",
                14: "Sharp Focus",
                30: "Deep Study",
                60: "Mastered Chapter",
                90: "Encyclopedic",
                180: "Omniscient"
            ]
        }
    }

    /// Returns the streak tier name for the current streak value.
    func streakLabel(for streak: Int) -> String? {
        let sortedKeys = streakTierNames.keys.sorted(by: >)
        guard let matchedKey = sortedKeys.first(where: { streak >= $0 }) else {
            return nil
        }
        return streakTierNames[matchedKey]
    }

    // MARK: - Boss Names (P28-INC-03)

    /// Themed boss encounter names.
    var bossNames: [String: String] {
        switch currentTheme {
        case .warrior:
            return [
                "laziness": "The Sloth Titan",
                "procrastination": "Delay Wraith",
                "doubt": "Shadow of Doubt",
                "distraction": "Chaos Siren",
                "apathy": "The Void"
            ]
        case .garden:
            return [
                "laziness": "Creeping Frost",
                "procrastination": "Weed Overgrowth",
                "doubt": "Withering Wind",
                "distraction": "Pest Swarm",
                "apathy": "Drought"
            ]
        case .scholar:
            return [
                "laziness": "Mental Fog",
                "procrastination": "The Procrastinator's Paradox",
                "doubt": "Imposter Syndrome",
                "distraction": "Info Overload",
                "apathy": "Blank Page"
            ]
        }
    }

    // MARK: - Accent Colors (P28-INC-04)

    struct AccentColorSet {
        let primary: Color
        let secondary: Color
        let streak: Color
        let surface: Color
    }

    var accentColors: AccentColorSet {
        switch currentTheme {
        case .warrior:
            return AccentColorSet(
                primary: Color(hex: "#DC2626"),    // Red — aggressive
                secondary: Color(hex: "#9B6BF7"),  // Purple glow
                streak: Color(hex: "#F97316"),     // Orange fire
                surface: Color(hex: "#1C1917")     // Dark charcoal
            )
        case .garden:
            return AccentColorSet(
                primary: Color(hex: "#22A559"),    // Green — growth
                secondary: Color(hex: "#86EFAC"),  // Light green
                streak: Color(hex: "#FDE047"),     // Sunshine yellow
                surface: Color(hex: "#F0FDF4")     // Soft green tint
            )
        case .scholar:
            return AccentColorSet(
                primary: Color(hex: "#2563EB"),    // Blue — calm knowledge
                secondary: Color(hex: "#93C5FD"),  // Light blue
                streak: Color(hex: "#A78BFA"),     // Violet
                surface: Color(hex: "#EFF6FF")     // Soft blue tint
            )
        }
    }

    // MARK: - NarrativeEngine Integration (P28-INC-06)

    /// Returns a themed motivational phrase for daily completion.
    func dailyCompletionPhrase() -> String {
        switch currentTheme {
        case .warrior:
            return "Another day conquered. Rest now — war resumes at dawn."
        case .garden:
            return "Beautiful growth today. Your garden thrives."
        case .scholar:
            return "Knowledge compounds. Today's lesson is tomorrow's wisdom."
        }
    }

    /// Returns a themed phrase for streak milestones.
    func streakMilestonePhrase(streak: Int) -> String {
        let label = streakLabel(for: streak) ?? "\(streak) days"
        switch currentTheme {
        case .warrior:
            return "Achievement unlocked: \(label). You are forged in fire."
        case .garden:
            return "Your roots grow deeper: \(label). Nature rewards patience."
        case .scholar:
            return "Milestone reached: \(label). Consistency is mastery."
        }
    }

    // MARK: - ForgeVoice Integration (P28-INC-07)

    /// Returns a themed greeting for voice announcements.
    func forgeVoiceGreeting() -> String {
        switch currentTheme {
        case .warrior:
            return "Rise, warrior. The forge awaits."
        case .garden:
            return "Good morning, gardener. Time to tend your seeds."
        case .scholar:
            return "A new day of learning begins. Let's begin."
        }
    }

    /// Returns a themed voice phrase for boss encounters.
    func bossEncounterPhrase(bossType: String) -> String {
        let name = bossNames[bossType] ?? "Unknown"
        switch currentTheme {
        case .warrior:
            return "A new challenge approaches: \(name). Prepare yourself."
        case .garden:
            return "\(name) threatens your garden. Time to protect what you've grown."
        case .scholar:
            return "A test appears: \(name). Apply what you've learned."
        }
    }

    // MARK: - Completion Sound Variant (P28-INC-08)

    /// Sound identifier variant per theme for habit completion feedback.
    var completionSoundName: String {
        switch currentTheme {
        case .warrior: return "completion_impact"
        case .garden: return "completion_chime"
        case .scholar: return "completion_page"
        }
    }
}
