import Foundation

/// Shared data model between the main app and the widget extension.
/// Stored in App Group UserDefaults for cross-process access.
struct RNFWidgetData: Codable {
    let streakCount: Int
    let dailyCompleted: Int
    let dailyGoal: Int
    let level: Int
    let questNames: [String]
    let questCompletions: [Bool]
    let lastUpdated: Date

    static let appGroupID = "group.com.rnf.shared"
    static let userDefaultsKey = "rnf_widget_data"

    var dailyProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(dailyCompleted) / Double(dailyGoal), 1.0)
    }

    static var placeholder: RNFWidgetData {
        RNFWidgetData(
            streakCount: 0,
            dailyCompleted: 0,
            dailyGoal: 3,
            level: 1,
            questNames: ["Morning Workout", "Read 10 Pages", "Meditate"],
            questCompletions: [false, false, false],
            lastUpdated: Date()
        )
    }
}
