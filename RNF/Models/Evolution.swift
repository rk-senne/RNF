import Foundation

enum EvolutionRank: String, Codable, CaseIterable, Identifiable {

    case disciple
    case awakened
    case ascendant
    case warlord
    case apex

    var id: String {
        rawValue
    }

    var tier: Int {
        switch self {

        case .disciple:
            return 1

        case .awakened:
            return 2

        case .ascendant:
            return 3

        case .warlord:
            return 4

        case .apex:
            return 5
        }
    }

}

enum EvolutionReward: String, Codable, CaseIterable {

    case title
    case minorXPBonus
    case skillTree
    case advancedQuests
    case avatarUpgrade
    case challengeTypes
    case profileBadge
    case specialRecognition

}

struct EvolutionTier: Codable, Identifiable, Equatable {

    var id: EvolutionRank {
        rank
    }

    let rank: EvolutionRank
    let name: String
    let description: String
    let requiredLevel: Int
    let requiredStreak: Int
    let rewards: [EvolutionReward]

}

struct EvolutionState: Codable, Equatable {

    let currentTier: EvolutionTier
    let nextTier: EvolutionTier?

}
