import Foundation

struct PerkSystem {

    static let defaultDailyXPCap = 100

    static func activePerks(
        skillNodes: [SkillTreeNode],
        unlockedSkills: [UserSkillUnlock]
    ) -> ActivePerkSummary {

        let unlockedNodeIDs = Set(unlockedSkills.map(\.skill_node_id))
        let effects = skillNodes
            .filter { unlockedNodeIDs.contains($0.id) }
            .compactMap(effect)

        return ActivePerkSummary(
            effects: effects,
            unlockedSkillNodeIDs: unlockedNodeIDs,
            xpMultiplierPercent: totalValue(for: .xpMultiplier, in: effects),
            statBonuses: statBonuses(in: effects),
            questRewardBonus: totalValue(for: .questRewardBonus, in: effects),
            streakProtectionCount: totalValue(for: .streakProtection, in: effects)
        )
    }

    static func modifiedXPReward(
        baseXP: Int,
        activePerks: ActivePerkSummary,
        currentDailyXP: Int = 0,
        dailyCap: Int = defaultDailyXPCap,
        streak: Int = 0
    ) -> Int {

        let sanitizedBaseXP = max(0, baseXP)
        let sanitizedMultiplier = max(0, activePerks.xpMultiplierPercent)
        let bonusXP = (sanitizedBaseXP * sanitizedMultiplier) / 100
        let perkReward = sanitizedBaseXP + bonusXP
        let uncappedReward = Int(Double(perkReward) * StreakTierSystem.multiplier(for: streak))
        let remainingDailyXP = max(0, dailyCap - max(0, currentDailyXP))

        return min(uncappedReward, remainingDailyXP)
    }

    static func modifiedStatReward(
        baseStatGain: Int,
        statType: SkillTreePath,
        activePerks: ActivePerkSummary,
        currentStatValue: Int? = nil,
        statCap: Int = 100
    ) -> Int {

        let sanitizedBaseGain = max(0, baseStatGain)
        let bonusGain = max(0, activePerks.statBonuses[statType] ?? 0)
        let uncappedGain = sanitizedBaseGain + bonusGain

        guard let currentStatValue else {
            return uncappedGain
        }

        let remainingStatCapacity = max(0, statCap - max(0, currentStatValue))

        return min(uncappedGain, remainingStatCapacity)
    }

    static func modifiedQuestReward(
        baseReward: Int,
        activePerks: ActivePerkSummary
    ) -> Int {

        max(0, baseReward) + max(0, activePerks.questRewardBonus)
    }

    static func canUseStreakProtection(
        dailyLog: DailyLog,
        activePerks: ActivePerkSummary,
        forgivenessTokens: Int
    ) -> Bool {

        let availableProtection = max(0, forgivenessTokens)
            + max(0, activePerks.streakProtectionCount)

        return ForgivenessSystem.evaluate(
            dailyLog: dailyLog,
            forgivenessTokens: availableProtection,
            currentStreak: 0
        ).canUseForgiveness
    }

    static func effect(for node: SkillTreeNode) -> PerkEffect? {
        guard let effectType = effectType(for: node.perk_type) else {
            return nil
        }

        return PerkEffect(
            id: node.id,
            name: node.name,
            effect_type: effectType,
            value: max(0, node.perk_value),
            stat_type: effectType == .statBonus ? node.stat_type : nil,
            source_skill_node_id: node.id
        )
    }

    private static func totalValue(
        for effectType: PerkEffectType,
        in effects: [PerkEffect]
    ) -> Int {

        effects
            .filter { $0.effect_type == effectType }
            .reduce(0) { total, effect in
                total + effect.value
            }
    }

    private static func statBonuses(
        in effects: [PerkEffect]
    ) -> [SkillTreePath: Int] {

        effects.reduce(into: [:]) { bonuses, effect in
            guard
                effect.effect_type == .statBonus,
                let statType = effect.stat_type
            else {
                return
            }

            bonuses[statType, default: 0] += effect.value
        }
    }

    private static func effectType(for rawValue: String) -> PerkEffectType? {
        switch rawValue {

        case PerkEffectType.xpMultiplier.rawValue,
            "xp_bonus",
            "xp":
            return .xpMultiplier

        case PerkEffectType.statBonus.rawValue,
            "stat_multiplier":
            return .statBonus

        case PerkEffectType.questRewardBonus.rawValue,
            "quest_bonus",
            "daily_quest_bonus",
            "extra_daily_quest":
            return .questRewardBonus

        case PerkEffectType.streakProtection.rawValue,
            "forgiveness",
            "streak_protect":
            return .streakProtection

        default:
            return nil
        }
    }

}
