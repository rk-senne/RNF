import Foundation

struct Habit: Codable, Identifiable {

    let id: UUID
    let name: String
    let description: String?
    let xpReward: Int
    let isCore: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case xpReward = "xp_reward"
        case isCore = "is_core"
    }

    init(id: UUID, name: String, description: String? = nil, xpReward: Int, isCore: Bool = true) {
        self.id = id
        self.name = name
        self.description = description
        self.xpReward = xpReward
        self.isCore = isCore
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        xpReward = try container.decode(Int.self, forKey: .xpReward)
        isCore = try container.decodeIfPresent(Bool.self, forKey: .isCore) ?? true
    }

}
