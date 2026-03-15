import Foundation

struct QuestMapper {

    static func toHabits(_ quests: [Quest]) -> [Habit] {

        quests.map { quest in

            Habit(
                id: quest.id,
                name: quest.title,
                description: quest.description,
                xpReward: quest.xp_reward
            )

        }

    }

}
