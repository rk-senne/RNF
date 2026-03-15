import Foundation

struct Habit: Codable, Identifiable {

    let id: UUID
    let name: String
    let description: String?
    let xpReward: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case xpReward = "xp_reward"
    }

}
