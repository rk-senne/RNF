import Foundation

struct StatSystem {

    static func applyReward(
        stats: inout Stats,
        for habitName: String,
        activePerks: ActivePerkSummary = .empty
    ) {

        switch habitName {

        case "Workout":
            applyStatReward(.strength, to: &stats, activePerks: activePerks)
            applyStatReward(.energy, to: &stats, activePerks: activePerks)

        case "Read 10 Pages":
            applyStatReward(.focus, to: &stats, activePerks: activePerks)
            applyStatReward(.mind, to: &stats, activePerks: activePerks)

        case "Meditate":
            applyStatReward(.wisdom, to: &stats, activePerks: activePerks)
            applyStatReward(.spirit, to: &stats, activePerks: activePerks)

        case "Cold Shower":
            applyStatReward(.discipline, to: &stats, activePerks: activePerks)
            applyStatReward(.energy, to: &stats, activePerks: activePerks)

        case "Drink Water":
            applyStatReward(.energy, to: &stats, activePerks: activePerks)

        case "Stretch":
            applyStatReward(.energy, to: &stats, activePerks: activePerks)
            applyStatReward(.spirit, to: &stats, activePerks: activePerks)

        case "Journal":
            applyStatReward(.wisdom, to: &stats, activePerks: activePerks)
            applyStatReward(.mind, to: &stats, activePerks: activePerks)

        case "Walk 10 Minutes":
            applyStatReward(.energy, to: &stats, activePerks: activePerks)
            applyStatReward(.strength, to: &stats, activePerks: activePerks)

        default:
            break
        }

    }

    private static func applyStatReward(
        _ statType: SkillTreePath,
        to stats: inout Stats,
        activePerks: ActivePerkSummary
    ) {

        let reward = PerkSystem.modifiedStatReward(
            baseStatGain: 1,
            statType: statType,
            activePerks: activePerks,
            currentStatValue: statValue(statType, in: stats)
        )

        switch statType {

        case .strength:
            stats.strength += reward

        case .discipline:
            stats.discipline += reward

        case .focus:
            stats.focus += reward

        case .energy:
            stats.energy += reward

        case .wisdom:
            stats.wisdom += reward

        case .mind:
            stats.mind += reward

        case .spirit:
            stats.spirit += reward
        }
    }

    private static func statValue(
        _ statType: SkillTreePath,
        in stats: Stats
    ) -> Int {

        switch statType {

        case .strength:
            return stats.strength

        case .discipline:
            return stats.discipline

        case .focus:
            return stats.focus

        case .energy:
            return stats.energy

        case .wisdom:
            return stats.wisdom

        case .mind:
            return stats.mind

        case .spirit:
            return stats.spirit
        }
    }

}
