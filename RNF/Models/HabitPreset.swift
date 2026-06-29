import Foundation

struct HabitPreset: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: Category
    let stat: String
    let xpReward: Int

    enum Category: String, Codable, CaseIterable {
        case body = "Body"
        case mind = "Mind"
        case spirit = "Spirit"
    }

    static let all: [HabitPreset] = [
        // Body
        HabitPreset(id: "cold_shower", name: "Cold shower", category: .body, stat: "energy", xpReward: 10),
        HabitPreset(id: "walk_10min", name: "10-minute walk", category: .body, stat: "strength", xpReward: 10),
        HabitPreset(id: "stretch", name: "Stretch / mobility", category: .body, stat: "energy", xpReward: 10),
        HabitPreset(id: "no_junk", name: "No junk food", category: .body, stat: "discipline", xpReward: 10),
        // Mind
        HabitPreset(id: "read_10", name: "Read 10 pages", category: .mind, stat: "wisdom", xpReward: 10),
        HabitPreset(id: "journal", name: "Journal 5 minutes", category: .mind, stat: "mind", xpReward: 10),
        HabitPreset(id: "meditate", name: "Meditate 5 minutes", category: .mind, stat: "focus", xpReward: 10),
        HabitPreset(id: "no_phone", name: "No phone first hour", category: .mind, stat: "discipline", xpReward: 10),
        // Spirit
        HabitPreset(id: "gratitude", name: "Gratitude list", category: .spirit, stat: "spirit", xpReward: 10),
        HabitPreset(id: "hydrate", name: "Hydrate 2L water", category: .spirit, stat: "energy", xpReward: 10),
        HabitPreset(id: "sleep_early", name: "Sleep before midnight", category: .spirit, stat: "discipline", xpReward: 10),
        HabitPreset(id: "breathing", name: "Deep breathing 3 min", category: .spirit, stat: "focus", xpReward: 10),
    ]
}
