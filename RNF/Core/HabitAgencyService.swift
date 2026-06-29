import Foundation

struct HabitAgencyService {
    private static let selectedKey = "rnf_selected_presets"
    private static let customKey = "rnf_custom_habits"

    // MARK: - Preset Selection

    static func saveSelections(_ presetIDs: [String]) {
        UserDefaults.standard.set(presetIDs, forKey: selectedKey)
    }

    static func loadSelections() -> [String] {
        UserDefaults.standard.stringArray(forKey: selectedKey) ?? []
    }

    static func selectedPresets() -> [HabitPreset] {
        let ids = loadSelections()
        return HabitPreset.all.filter { ids.contains($0.id) }
    }

    // MARK: - Custom Habits

    static func saveCustomHabits(_ habits: [CustomHabit]) {
        if let data = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(data, forKey: customKey)
        }
    }

    static func loadCustomHabits() -> [CustomHabit] {
        guard let data = UserDefaults.standard.data(forKey: customKey),
              let habits = try? JSONDecoder().decode([CustomHabit].self, from: data)
        else { return [] }
        return habits
    }

    // MARK: - Unlock State

    static func customSlots(forStreak streak: Int) -> Int {
        switch streak {
        case 60...: return 3
        case 30...: return 2
        case 14...: return 1
        default: return 0
        }
    }

    static func canSwap(forStreak streak: Int) -> Bool {
        streak >= 7
    }
}

struct CustomHabit: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let stat: String
    let xpReward: Int

    init(name: String, stat: String) {
        self.id = UUID()
        self.name = name
        self.stat = stat
        self.xpReward = 10
    }
}
