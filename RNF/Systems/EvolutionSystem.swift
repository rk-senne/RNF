import Foundation

struct EvolutionSystem {

    static let tiers: [EvolutionTier] = [
        EvolutionTier(
            rank: .disciple,
            name: "Disciple",
            description: "Beginning the discipline journey",
            requiredLevel: 1,
            requiredStreak: 0,
            rewards: []
        ),
        EvolutionTier(
            rank: .awakened,
            name: "Awakened",
            description: "Conscious commitment to improvement",
            requiredLevel: 5,
            requiredStreak: 7,
            rewards: [
                .title,
                .minorXPBonus
            ]
        ),
        EvolutionTier(
            rank: .ascendant,
            name: "Ascendant",
            description: "Mastery of personal habits",
            requiredLevel: SkillTreeSystem.unlockLevel,
            requiredStreak: 30,
            rewards: [
                .skillTree,
                .advancedQuests
            ]
        ),
        EvolutionTier(
            rank: .warlord,
            name: "Warlord",
            description: "Command of discipline across life",
            requiredLevel: 15,
            requiredStreak: 90,
            rewards: [
                .title,
                .avatarUpgrade,
                .challengeTypes
            ]
        ),
        EvolutionTier(
            rank: .apex,
            name: "Apex",
            description: "Elite long-term consistency",
            requiredLevel: 20,
            requiredStreak: 180,
            rewards: [
                .title,
                .profileBadge,
                .specialRecognition
            ]
        )
    ]

    static func state(for profile: Profile) -> EvolutionState {
        let currentTier = currentTier(for: profile)

        return EvolutionState(
            currentTier: currentTier,
            nextTier: nextTier(after: currentTier)
        )
    }

    static func currentTier(for profile: Profile) -> EvolutionTier {
        tiers
            .filter { tier in
                isUnlocked(tier, for: profile)
            }
            .max { first, second in
                first.rank.tier < second.rank.tier
            } ?? tiers[0]
    }

    static func nextTier(after tier: EvolutionTier) -> EvolutionTier? {
        tiers.first { candidate in
            candidate.rank.tier == tier.rank.tier + 1
        }
    }

    static func newlyReachedTier(
        previousRank: EvolutionRank,
        profile: Profile
    ) -> EvolutionTier? {

        let currentTier = currentTier(for: profile)

        guard currentTier.rank.tier > previousRank.tier else {
            return nil
        }

        return currentTier
    }

    static func isUnlocked(
        _ tier: EvolutionTier,
        for profile: Profile
    ) -> Bool {

        effectiveLevel(for: profile) >= tier.requiredLevel
        && profile.streak >= tier.requiredStreak
    }

    private static func effectiveLevel(for profile: Profile) -> Int {
        XPSystem.effectiveLevel(for: profile)
    }

}
