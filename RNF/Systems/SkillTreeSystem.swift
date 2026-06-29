import Foundation

struct SkillTreeSystem {

    static let unlockLevel = 10

    static func isSkillTreeUnlocked(for profile: Profile) -> Bool {
        effectiveLevel(for: profile) >= unlockLevel
    }

    static func skillPointsEarned(forLevel level: Int) -> Int {
        guard level >= unlockLevel else {
            return 0
        }

        return ((level - unlockLevel) / 5) + 1
    }

    static func skillPointsEarned(for profile: Profile) -> Int {
        skillPointsEarned(forLevel: effectiveLevel(for: profile))
    }

    static func unlockState(
        profile: Profile,
        unlockedSkills: [UserSkillUnlock]
    ) -> SkillTreeUnlockState {

        let unlockedNodeIDs = Set(unlockedSkills.map(\.skill_node_id))
        let spentPoints = unlockedNodeIDs.count
        let availableSkillPoints = max(
            0,
            skillPointsEarned(for: profile) - spentPoints
        )

        return SkillTreeUnlockState(
            availableSkillPoints: availableSkillPoints,
            unlockedNodeIDs: unlockedNodeIDs
        )
    }

    static func canUnlock(
        _ node: SkillTreeNode,
        profile: Profile,
        state: SkillTreeUnlockState
    ) -> Bool {

        guard
            isSkillTreeUnlocked(for: profile),
            state.availableSkillPoints > 0,
            !state.unlockedNodeIDs.contains(node.id)
        else {
            return false
        }

        if let requiredStat = node.required_stat,
           statValue(for: node.stat_type, in: profile) < requiredStat {
            return false
        }

        if let requiredNode = node.required_node,
           !state.unlockedNodeIDs.contains(requiredNode) {
            return false
        }

        return true
    }

    static func statValue(
        for path: SkillTreePath,
        in profile: Profile
    ) -> Int {

        switch path {

        case .strength:
            return profile.strength

        case .discipline:
            return profile.discipline

        case .focus:
            return profile.focus

        case .energy:
            return profile.energy

        case .wisdom:
            return profile.wisdom

        case .mind:
            return profile.mind

        case .spirit:
            return profile.spirit
        }
    }

    private static func effectiveLevel(for profile: Profile) -> Int {
        XPSystem.effectiveLevel(for: profile)
    }

}
