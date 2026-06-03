import Foundation

struct QuestMapper {

    static func toHabit(
        _ quest: Quest,
        activePerks: ActivePerkSummary = .empty
    ) -> Habit {

        Habit(
            id: quest.id,
            name: quest.title,
            description: quest.description,
            xpReward: PerkSystem.modifiedQuestReward(
                baseReward: quest.xp_reward,
                activePerks: activePerks
            )
        )

    }

    static func toHabits(
        _ quests: [Quest],
        activePerks: ActivePerkSummary = .empty
    ) -> [Habit] {

        quests.map { quest in

            toHabit(
                quest,
                activePerks: activePerks
            )

        }

    }

}
