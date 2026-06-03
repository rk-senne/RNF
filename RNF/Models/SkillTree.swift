import Foundation

enum SkillTreePath: String, Codable, CaseIterable {

    case strength
    case discipline
    case focus
    case energy
    case wisdom
    case mind
    case spirit

}

enum SkillTreeTier: Int, Codable, CaseIterable {

    case tier1 = 1
    case tier2 = 2
    case tier3 = 3

}

struct SkillTreeNode: Codable, Identifiable, Equatable {

    let id: UUID
    let name: String
    let stat_type: SkillTreePath
    let tier: SkillTreeTier
    let required_stat: Int?
    let required_node: UUID?
    let perk_type: String
    let perk_value: Int

}

struct UserSkillUnlock: Codable, Identifiable, Equatable {

    let id: UUID
    let user_id: UUID
    let skill_node_id: UUID
    let unlocked_at: Date

}

struct SkillTreeUnlockState: Codable, Equatable {

    let availableSkillPoints: Int
    let unlockedNodeIDs: Set<UUID>

}
