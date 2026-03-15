import Foundation

struct QuestRepository {

    static let all: [Quest] = [

        Quest(
            id: UUID(),
            title: "Drink Water",
            description: "Hydrate your body",
            stat_strength: nil,
            stat_discipline: 1,
            stat_focus: nil,
            stat_energy: 1,
            stat_wisdom: nil,
            stat_mind: nil,
            stat_spirit: nil,
            xp_reward: 10,
            difficulty: 1,
            category: "discipline"
        ),

        Quest(
            id: UUID(),
            title: "Read 10 Pages",
            description: "Sharpen the mind",
            stat_strength: nil,
            stat_discipline: nil,
            stat_focus: 1,
            stat_energy: nil,
            stat_wisdom: 1,
            stat_mind: 1,
            stat_spirit: nil,
            xp_reward: 15,
            difficulty: 1,
            category: "mind"
        ),

        Quest(
            id: UUID(),
            title: "Workout",
            description: "Build physical strength",
            stat_strength: 2,
            stat_discipline: 1,
            stat_focus: nil,
            stat_energy: 1,
            stat_wisdom: nil,
            stat_mind: nil,
            stat_spirit: nil,
            xp_reward: 20,
            difficulty: 2,
            category: "strength"
        ),

        Quest(
            id: UUID(),
            title: "Meditate",
            description: "Calm the mind",
            stat_strength: nil,
            stat_discipline: 1,
            stat_focus: 1,
            stat_energy: nil,
            stat_wisdom: nil,
            stat_mind: 1,
            stat_spirit: 1,
            xp_reward: 10,
            difficulty: 1,
            category: "spirit"
        ),

        Quest(
            id: UUID(),
            title: "Journal",
            description: "Reflect and gain clarity",
            stat_strength: nil,
            stat_discipline: nil,
            stat_focus: 1,
            stat_energy: nil,
            stat_wisdom: 1,
            stat_mind: 1,
            stat_spirit: nil,
            xp_reward: 15,
            difficulty: 1,
            category: "wisdom"
        ),

        Quest(
            id: UUID(),
            title: "Cold Shower",
            description: "Train discipline",
            stat_strength: nil,
            stat_discipline: 2,
            stat_focus: nil,
            stat_energy: 2,
            stat_wisdom: nil,
            stat_mind: nil,
            stat_spirit: nil,
            xp_reward: 20,
            difficulty: 2,
            category: "discipline"
        ),

        Quest(
            id: UUID(),
            title: "Walk 10 Minutes",
            description: "Move your body",
            stat_strength: 1,
            stat_discipline: nil,
            stat_focus: nil,
            stat_energy: 1,
            stat_wisdom: nil,
            stat_mind: nil,
            stat_spirit: nil,
            xp_reward: 10,
            difficulty: 1,
            category: "energy"
        )
    ]

}
