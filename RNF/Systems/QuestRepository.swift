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
            difficulty: .easy,
            cadence: .daily,
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
            difficulty: .medium,
            cadence: .daily,
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
            difficulty: .hard,
            cadence: .daily,
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
            difficulty: .easy,
            cadence: .daily,
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
            difficulty: .medium,
            cadence: .daily,
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
            difficulty: .hard,
            cadence: .daily,
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
            difficulty: .easy,
            cadence: .daily,
            category: "energy"
        ),

        // GAP 10: Weekly-cadence quests for gradual habit expansion.
        // Spec: RNF_RETENTION_SYSTEM.md — "Habits unlock over time. Week 2: add movement. Week 3: add reading."

        Quest(
            id: UUID(),
            title: "Daily Movement",
            description: "Add a movement habit to your routine",
            stat_strength: 1,
            stat_discipline: 1,
            stat_focus: nil,
            stat_energy: 2,
            stat_wisdom: nil,
            stat_mind: nil,
            stat_spirit: nil,
            xp_reward: 15,
            difficulty: .medium,
            cadence: .weekly,
            category: "energy"
        ),

        Quest(
            id: UUID(),
            title: "Daily Reading",
            description: "Add a reading habit to your routine",
            stat_strength: nil,
            stat_discipline: 1,
            stat_focus: 2,
            stat_energy: nil,
            stat_wisdom: 1,
            stat_mind: 1,
            stat_spirit: nil,
            xp_reward: 15,
            difficulty: .medium,
            cadence: .weekly,
            category: "mind"
        ),

        Quest(
            id: UUID(),
            title: "Evening Reflection",
            description: "Add journaling or meditation to your routine",
            stat_strength: nil,
            stat_discipline: 1,
            stat_focus: 1,
            stat_energy: nil,
            stat_wisdom: 1,
            stat_mind: nil,
            stat_spirit: 2,
            xp_reward: 15,
            difficulty: .medium,
            cadence: .weekly,
            category: "spirit"
        )
    ]

}
