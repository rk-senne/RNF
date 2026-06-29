import Foundation

struct Discovery: Codable, Identifiable {
    let id: String
    let name: String
    let message: String
    let xp: Int
    let rarity: Rarity

    enum Rarity: String, Codable {
        case common, uncommon, rare, legendary
    }
}

struct DiscoveryRecord: Codable, Identifiable {
    var id: String { discoveryID }
    let discoveryID: String
    let earnedDate: String
}
