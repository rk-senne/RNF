import Foundation

/// Pure deterministic system for calculating daily intensity levels.
/// Intensity determines XP multiplier and streak validity.
/// Any completion >= .ember keeps the streak alive.
struct IntensitySystem {

    // MARK: - Types

    enum IntensityLevel: String, Codable, CaseIterable, Comparable {
        case rest = "Rest"
        case ember = "Ember"
        case flame = "Flame"
        case blaze = "Blaze"
        case inferno = "Inferno"

        var displayName: String { rawValue }

        var emoji: String {
            switch self {
            case .rest: return "💤"
            case .ember: return "🕯️"
            case .flame: return "🔥"
            case .blaze: return "⚡"
            case .inferno: return "💎"
            }
        }

        var description: String {
            switch self {
            case .rest: return "No habits completed"
            case .ember: return "At least 1 habit completed"
            case .flame: return "50%+ habits completed"
            case .blaze: return "All habits + workout or reading"
            case .inferno: return "All habits + workout + reading"
            }
        }

        static func < (lhs: IntensityLevel, rhs: IntensityLevel) -> Bool {
            let order: [IntensityLevel] = [.rest, .ember, .flame, .blaze, .inferno]
            guard let l = order.firstIndex(of: lhs),
                  let r = order.firstIndex(of: rhs) else { return false }
            return l < r
        }
    }

    // MARK: - Calculation

    /// Calculate the intensity level for a day based on completions.
    static func calculateIntensity(
        habitsCompleted: Int,
        totalHabits: Int,
        hasWorkout: Bool,
        hasReading: Bool
    ) -> IntensityLevel {

        guard totalHabits > 0 else { return .rest }
        guard habitsCompleted > 0 else { return .rest }

        let allHabits = habitsCompleted >= totalHabits

        // Inferno: All habits + workout + reading
        if allHabits && hasWorkout && hasReading {
            return .inferno
        }

        // Blaze: All habits + at least one extra (workout or reading)
        if allHabits && (hasWorkout || hasReading) {
            return .blaze
        }

        // Flame: 50%+ habits completed
        let ratio = Double(habitsCompleted) / Double(totalHabits)
        if ratio >= 0.5 {
            return .flame
        }

        // Ember: At least 1 habit completed
        return .ember
    }

    // MARK: - XP Multiplier

    /// XP multiplier for the given intensity level.
    static func xpMultiplier(for level: IntensityLevel) -> Double {
        switch level {
        case .rest: return 0.0
        case .ember: return 1.0
        case .flame: return 1.5
        case .blaze: return 2.0
        case .inferno: return 3.0
        }
    }

    // MARK: - Streak Validity

    /// Any intensity level >= ember keeps the streak alive.
    /// This is the core flexible intensity principle:
    /// even a single habit completion on a busy day preserves your streak.
    static func meetsStreakMinimum(_ level: IntensityLevel) -> Bool {
        level >= .ember
    }

    // MARK: - Calendar Color

    /// Color name for calendar display gradient.
    static func colorName(for level: IntensityLevel) -> String {
        switch level {
        case .rest: return "calendarMissed"
        case .ember: return "calendarEmber"
        case .flame: return "calendarFlame"
        case .blaze: return "calendarBlaze"
        case .inferno: return "calendarInferno"
        }
    }
}
