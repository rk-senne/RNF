import Foundation

struct QuestGenerator {

    static func generateDailyQuests(
        profile: Profile,
        quests: [Quest]
    ) -> (main: Quest?, side: [Quest]) {

        // MARK: Map player stats

        let statMap: [(name: String, value: Int)] = [
            ("strength", profile.strength),
            ("discipline", profile.discipline),
            ("focus", profile.focus),
            ("energy", profile.energy),
            ("wisdom", profile.wisdom),
            ("mind", profile.mind),
            ("spirit", profile.spirit)
        ]

        // MARK: Find weakest stat

        guard let weakest = statMap.min(by: { $0.value < $1.value }) else {
            return (nil, [])
        }

        // MARK: Select main quest based on weakest stat

        let mainQuest = quests.first { quest in

            switch weakest.name {

            case "strength":
                return (quest.stat_strength ?? 0) > 0

            case "discipline":
                return (quest.stat_discipline ?? 0) > 0

            case "focus":
                return (quest.stat_focus ?? 0) > 0

            case "energy":
                return (quest.stat_energy ?? 0) > 0

            case "wisdom":
                return (quest.stat_wisdom ?? 0) > 0

            case "mind":
                return (quest.stat_mind ?? 0) > 0

            case "spirit":
                return (quest.stat_spirit ?? 0) > 0

            default:
                return false
            }

        }

        // MARK: Generate side quests

        let sideQuests = quests
            .filter { quest in
                quest.id != mainQuest?.id
            }
            .shuffled()
            .prefix(4)

        return (
            main: mainQuest,
            side: Array(sideQuests)
        )
    }

}
