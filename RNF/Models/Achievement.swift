import Foundation

struct Achievement: Codable, Identifiable {

    enum Category: String, Codable {
        case streak
        case level
        case habits
        case workouts
        case reading
        case boss
        case social
    }

    let id: String
    let name: String
    let description: String
    let category: Category
    let requirement: Int
    let iconName: String
    var unlockedAt: Date?

    var isUnlocked: Bool { unlockedAt != nil }

    static let all: [Achievement] = [
        Achievement(id: "streak_7", name: "Week Warrior", description: "7-day streak", category: .streak, requirement: 7, iconName: "flame.fill"),
        Achievement(id: "streak_30", name: "Monthly Master", description: "30-day streak", category: .streak, requirement: 30, iconName: "flame.fill"),
        Achievement(id: "streak_90", name: "Iron Will", description: "90-day streak", category: .streak, requirement: 90, iconName: "flame.fill"),
        Achievement(id: "level_5", name: "Awakened", description: "Reach level 5", category: .level, requirement: 5, iconName: "arrow.up.circle.fill"),
        Achievement(id: "level_10", name: "Ascendant", description: "Reach level 10", category: .level, requirement: 10, iconName: "arrow.up.circle.fill"),
        Achievement(id: "level_20", name: "Apex", description: "Reach level 20", category: .level, requirement: 20, iconName: "arrow.up.circle.fill"),
        Achievement(id: "habits_50", name: "Half Century", description: "Complete 50 habits", category: .habits, requirement: 50, iconName: "checkmark.circle.fill"),
        Achievement(id: "habits_500", name: "Relentless", description: "Complete 500 habits", category: .habits, requirement: 500, iconName: "checkmark.circle.fill"),
        Achievement(id: "workouts_30", name: "Athlete", description: "30 workouts", category: .workouts, requirement: 30, iconName: "figure.run"),
        Achievement(id: "boss_1", name: "Slayer", description: "Defeat first boss", category: .boss, requirement: 1, iconName: "shield.fill"),
        Achievement(id: "boss_5", name: "Champion", description: "Defeat 5 bosses", category: .boss, requirement: 5, iconName: "shield.fill"),
    ]
}
