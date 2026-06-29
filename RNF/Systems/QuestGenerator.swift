import Foundation

struct QuestGenerator {

    static func selectQuestForWeakestStat(
        profile: Profile,
        quests: [Quest]
    ) -> Quest? {

        guard let weakestStat = weakestStatName(for: profile) else {
            return nil
        }

        return quests.first { quest in
            questTargets(quest, statName: weakestStat)
        }
    }

    static func selectWeeklyHabitUnlock(
        profile: Profile,
        quests: [Quest],
        asOf date: Date = Date(),
        calendar: Calendar = .current
    ) -> Quest? {

        guard isWeeklyHabitUnlockAvailable(
            profile: profile,
            asOf: date,
            calendar: calendar
        ) else {
            return nil
        }

        return quests.first { quest in
            quest.cadence == .weekly
        }
    }

    static func generateDailyQuests(
        profile: Profile,
        quests: [Quest]
    ) -> (main: Quest?, side: [Quest]) {

        // MARK: Select main quest based on weakest stat

        let mainQuest = selectQuestForWeakestStat(
            profile: profile,
            quests: quests
        )

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

    // P20-EXP-13c: Check if focus session should be suggested
    static func shouldSuggestFocusSession(profile: Profile) -> Bool {
        let weakest = weakestStatName(for: profile)
        return weakest == "focus" || weakest == "mind"
    }

    private static func weakestStatName(for profile: Profile) -> String? {

        let statMap: [(name: String, value: Int)] = [
            ("strength", profile.strength),
            ("discipline", profile.discipline),
            ("focus", profile.focus),
            ("energy", profile.energy),
            ("wisdom", profile.wisdom),
            ("mind", profile.mind),
            ("spirit", profile.spirit)
        ]

        return statMap.min(by: { $0.value < $1.value })?.name
    }

    private static func isWeeklyHabitUnlockAvailable(
        profile: Profile,
        asOf date: Date,
        calendar: Calendar
    ) -> Bool {

        guard let createdAt = profile.created_at else {
            return false
        }

        let activeDays = calendar.dateComponents(
            [.day],
            from: createdAt,
            to: date
        ).day ?? 0

        return activeDays >= 7
    }

    private static func questTargets(
        _ quest: Quest,
        statName: String
    ) -> Bool {

        switch statName {

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

}
