import Foundation

struct Boss: Codable, Identifiable {

    enum BossType: String, Codable, CaseIterable {
        case procrastination
        case doubt
        case laziness
        case distraction
        case apathy
    }

    enum Status: String, Codable {
        case locked
        case active
        case defeated
    }

    let id: UUID
    var user_id: UUID?
    let bossType: BossType
    var maxHP: Int
    var currentHP: Int
    var status: Status
    var defeated_at: Date?
    var created_at: Date?

    enum CodingKeys: String, CodingKey {
        case id, status, user_id
        case bossType = "boss_type"
        case maxHP = "max_hp"
        case currentHP = "current_hp"
        case defeated_at, created_at
    }

    var isDefeated: Bool { currentHP <= 0 }
    var hpProgress: Double {
        guard maxHP > 0 else { return 0 }
        return Double(maxHP - currentHP) / Double(maxHP)
    }

    static func create(type: BossType, level: Int) -> Boss {
        let hp = 10 + (level * 5)
        return Boss(
            id: UUID(), user_id: nil, bossType: type,
            maxHP: hp, currentHP: hp, status: .active,
            defeated_at: nil, created_at: nil
        )
    }
}
