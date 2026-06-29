import Foundation

struct StreakTierSystem {
    enum Tier: String, CaseIterable {
        case spark = "Spark"
        case ember = "Ember"
        case flame = "Flame"
        case blaze = "Blaze"
        case inferno = "Inferno"
        case eternal = "Eternal"

        var description: String {
            switch self {
            case .spark: return "The flame flickers. A single breeze could end it."
            case .ember: return "Coals glow beneath the surface. There is heat now."
            case .flame: return "The fire is visible. Others might notice."
            case .blaze: return "The Forge burns hot. Your actions carry weight."
            case .inferno: return "Unstoppable heat. The system bends to serve you."
            case .eternal: return "The fire no longer needs fuel. It IS you."
            }
        }
    }

    static func tier(for streak: Int) -> Tier {
        switch streak {
        case 0...6: return .spark
        case 7...13: return .ember
        case 14...29: return .flame
        case 30...59: return .blaze
        case 60...89: return .inferno
        default: return .eternal
        }
    }

    static func multiplier(for streak: Int) -> Double {
        switch tier(for: streak) {
        case .spark: return 1.0
        case .ember: return 1.05
        case .flame: return 1.10
        case .blaze: return 1.15
        case .inferno: return 1.20
        case .eternal: return 1.25
        }
    }

    static func icon(for tier: Tier) -> String {
        switch tier {
        case .spark: return "🌱"
        case .ember: return "🔥"
        case .flame: return "⚡"
        case .blaze: return "💎"
        case .inferno: return "🗡️"
        case .eternal: return "👑"
        }
    }
}
