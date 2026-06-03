import Foundation

enum PerkEffectType: String, Codable, CaseIterable {

    case xpMultiplier = "xp_multiplier"
    case statBonus = "stat_bonus"
    case questRewardBonus = "quest_reward_bonus"
    case streakProtection = "streak_protection"

}

struct PerkEffect: Codable, Identifiable, Equatable {

    let id: UUID
    let name: String
    let effect_type: PerkEffectType
    let value: Int
    let stat_type: SkillTreePath?
    let source_skill_node_id: UUID?

}

struct ActivePerkSummary: Codable, Equatable {

    let effects: [PerkEffect]
    let unlockedSkillNodeIDs: Set<UUID>
    let xpMultiplierPercent: Int
    let statBonuses: [SkillTreePath: Int]
    let questRewardBonus: Int
    let streakProtectionCount: Int

    static let empty = ActivePerkSummary(
        effects: [],
        unlockedSkillNodeIDs: [],
        xpMultiplierPercent: 0,
        statBonuses: [:],
        questRewardBonus: 0,
        streakProtectionCount: 0
    )

}
