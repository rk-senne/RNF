import Foundation

struct QuestMapper {

    static func toHabit(_ quest: Quest) -> Habit {

        Habit(
            id: quest.id,
            name: quest.title,
            description: quest.description,
            xpReward: quest.xp_reward
        )

    }

    static func toHabits(_ quests: [Quest]) -> [Habit] {

        quests.map { quest in

            toHabit(quest)

        }

    }

}
