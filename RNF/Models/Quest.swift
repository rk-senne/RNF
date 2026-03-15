import Foundation

struct Quest: Codable, Identifiable {

    let id: UUID

    let title: String
    let description: String

    let stat_strength: Int?
    let stat_discipline: Int?
    let stat_focus: Int?
    let stat_energy: Int?
    let stat_wisdom: Int?
    let stat_mind: Int?
    let stat_spirit: Int?

    let xp_reward: Int
    let difficulty: Int
    let category: String

}
