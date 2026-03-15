import Foundation

struct StatSystem {

    static func applyReward(
        stats: inout Stats,
        for habitName: String
    ) {

        switch habitName {

        case "Workout":
            stats.strength += 1
            stats.energy += 1

        case "Read 10 Pages":
            stats.focus += 1
            stats.mind += 1

        case "Meditate":
            stats.wisdom += 1
            stats.spirit += 1

        case "Cold Shower":
            stats.discipline += 1
            stats.energy += 1

        case "Drink Water":
            stats.energy += 1

        case "Stretch":
            stats.energy += 1
            stats.spirit += 1

        case "Journal":
            stats.wisdom += 1
            stats.mind += 1

        case "Walk 10 Minutes":
            stats.energy += 1
            stats.strength += 1

        default:
            break
        }

    }

}
