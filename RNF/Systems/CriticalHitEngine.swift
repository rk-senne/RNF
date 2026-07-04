import Foundation

// P24-RET-01/02/05: Critical Hit system for XP rewards
// Pure deterministic system — seeded RNG ensures same result for same user+day+habit

struct CriticalHitEngine {

    // MARK: - Types

    struct CritResult: Equatable {
        let isCritical: Bool
        let multiplier: Double
        let bonusXP: Int
        let baseXP: Int
        let totalXP: Int
    }

    // MARK: - Configuration

    static let baseCritRate: Double = 0.20
    static let minMultiplier: Double = 2.0
    static let maxMultiplier: Double = 3.0

    // MARK: - Streak Tier Crit Bonuses

    /// Additional crit chance based on streak tier
    static func streakTierBonus(for tier: StreakTierSystem.Tier) -> Double {
        switch tier {
        case .spark: return 0.0
        case .ember: return 0.05
        case .flame: return 0.10
        case .blaze: return 0.15
        case .inferno: return 0.20
        case .eternal: return 0.25
        }
    }

    // MARK: - Core Logic

    /// Calculate critical hit for a habit completion.
    /// Uses seeded RNG based on userID + date + habitID for deterministic results.
    static func evaluate(
        baseXP: Int,
        userID: UUID,
        habitID: UUID,
        date: Date = Date(),
        streakTier: StreakTierSystem.Tier = .spark
    ) -> CritResult {

        let seed = generateSeed(userID: userID, habitID: habitID, date: date)
        var rng = SeededRNG(seed: seed)

        let effectiveCritRate = min(baseCritRate + streakTierBonus(for: streakTier), 0.60)
        let critRoll = rng.nextDouble()
        let isCritical = critRoll < effectiveCritRate

        guard isCritical else {
            return CritResult(
                isCritical: false,
                multiplier: 1.0,
                bonusXP: 0,
                baseXP: baseXP,
                totalXP: baseXP
            )
        }

        // Multiplier between 2x and 3x
        let multiplierRoll = rng.nextDouble()
        let multiplier = minMultiplier + (multiplierRoll * (maxMultiplier - minMultiplier))
        let roundedMultiplier = (multiplier * 100).rounded() / 100

        let totalXP = Int(Double(baseXP) * roundedMultiplier)
        let bonusXP = totalXP - baseXP

        return CritResult(
            isCritical: true,
            multiplier: roundedMultiplier,
            bonusXP: bonusXP,
            baseXP: baseXP,
            totalXP: totalXP
        )
    }

    /// Effective crit rate for display purposes
    static func effectiveCritRate(for streakTier: StreakTierSystem.Tier) -> Double {
        min(baseCritRate + streakTierBonus(for: streakTier), 0.60)
    }

    // MARK: - Seed Generation

    /// Creates a deterministic seed from user+day+habit combination.
    /// Same inputs always produce the same crit result within a single day.
    private static func generateSeed(userID: UUID, habitID: UUID, date: Date) -> UInt64 {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)

        var hasher = Hasher()
        hasher.combine(userID)
        hasher.combine(habitID)
        hasher.combine(year)
        hasher.combine(dayOfYear)

        let hashValue = hasher.finalize()
        return UInt64(bitPattern: Int64(hashValue))
    }
}

// MARK: - Seeded RNG

/// Simple seeded random number generator using SplitMix64 algorithm.
/// Provides deterministic sequences from a seed value.
struct SeededRNG: RandomNumberGenerator {

    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func nextDouble() -> Double {
        let value = next()
        return Double(value &>> 11) * (1.0 / Double(1 << 53))
    }
}
