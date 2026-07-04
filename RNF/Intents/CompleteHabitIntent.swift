import AppIntents
import Foundation
import os
import WidgetKit

// MARK: - P26-APL-01: Complete Habit Intent (Siri / Shortcuts)

/// Marks a habit as complete for today via Siri, Shortcuts, or Spotlight.
struct CompleteHabitIntent: AppIntent {

    static var title: LocalizedStringResource = "Complete Habit"
    static var description = IntentDescription("Mark a habit as complete for today")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Habit Name", description: "The name of the habit to complete")
    var habitName: String

    static var parameterSummary: some ParameterSummary {
        Summary("Complete \(\.$habitName)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Bool> {
        let logger = Logger(subsystem: "com.rnf.app", category: "intents")

        // Load widget data to find matching habit
        guard let widgetData = Self.loadWidgetData() else {
            logger.error("CompleteHabitIntent: Could not load widget data")
            return .result(
                value: false,
                dialog: "I couldn't find your habits. Open RNF to sync your data."
            )
        }

        // Find the matching habit by name (case-insensitive)
        guard let habitIndex = widgetData.questNames.firstIndex(where: {
            $0.localizedCaseInsensitiveCompare(habitName) == .orderedSame
        }) else {
            let available = widgetData.questNames.joined(separator: ", ")
            return .result(
                value: false,
                dialog: "I couldn't find \"\(habitName)\". Your habits are: \(available)"
            )
        }

        // Check if already completed
        if habitIndex < widgetData.questCompletions.count && widgetData.questCompletions[habitIndex] {
            return .result(
                value: true,
                dialog: "\(habitName) is already done for today! 🎉"
            )
        }

        // Mark as complete in shared data
        var updatedCompletions = widgetData.questCompletions
        if habitIndex < updatedCompletions.count {
            updatedCompletions[habitIndex] = true
        }

        let updatedData = RNFWidgetData(
            streakCount: widgetData.streakCount,
            dailyCompleted: widgetData.dailyCompleted + 1,
            dailyGoal: widgetData.dailyGoal,
            level: widgetData.level,
            questNames: widgetData.questNames,
            questCompletions: updatedCompletions,
            lastUpdated: Date()
        )

        Self.writeWidgetData(updatedData)
        WidgetCenter.shared.reloadAllTimelines()

        logger.info("CompleteHabitIntent: Marked '\(habitName)' complete")

        let remaining = updatedData.dailyGoal - updatedData.dailyCompleted
        let dialog: String
        if remaining <= 0 {
            dialog = "Done! \(habitName) completed. All habits done for today! 🔥"
        } else {
            dialog = "Done! \(habitName) completed. \(remaining) more to go. 💪"
        }

        return .result(value: true, dialog: "\(dialog)")
    }

    // MARK: - Shared Data Helpers

    static func loadWidgetData() -> RNFWidgetData? {
        guard
            let defaults = UserDefaults(suiteName: RNFWidgetData.appGroupID),
            let data = defaults.data(forKey: RNFWidgetData.userDefaultsKey),
            let widgetData = try? JSONDecoder().decode(RNFWidgetData.self, from: data)
        else {
            return nil
        }
        return widgetData
    }

    static func writeWidgetData(_ widgetData: RNFWidgetData) {
        guard
            let defaults = UserDefaults(suiteName: RNFWidgetData.appGroupID),
            let encoded = try? JSONEncoder().encode(widgetData)
        else { return }
        defaults.set(encoded, forKey: RNFWidgetData.userDefaultsKey)
    }
}

// MARK: - P26-APL-11: Complete Habit From Widget Intent (Interactive Widgets)

/// Lightweight intent for interactive widget buttons. Marks a specific habit
/// by index as complete without opening the app.
struct CompleteHabitFromWidgetIntent: AppIntent {

    static var title: LocalizedStringResource = "Complete Habit from Widget"
    static var description = IntentDescription("Mark a habit as complete from a widget button")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Habit Index")
    var habitIndex: Int

    init() {
        self.habitIndex = 0
    }

    init(habitIndex: Int) {
        self.habitIndex = habitIndex
    }

    func perform() async throws -> some IntentResult {
        let logger = Logger(subsystem: "com.rnf.app", category: "intents")

        guard var widgetData = CompleteHabitIntent.loadWidgetData() else {
            logger.error("CompleteHabitFromWidgetIntent: Could not load widget data")
            return .result()
        }

        guard habitIndex >= 0, habitIndex < widgetData.questCompletions.count else {
            logger.error("CompleteHabitFromWidgetIntent: Index \(habitIndex) out of bounds")
            return .result()
        }

        // Already completed — no-op
        guard !widgetData.questCompletions[habitIndex] else {
            return .result()
        }

        var updatedCompletions = widgetData.questCompletions
        updatedCompletions[habitIndex] = true

        let updatedData = RNFWidgetData(
            streakCount: widgetData.streakCount,
            dailyCompleted: widgetData.dailyCompleted + 1,
            dailyGoal: widgetData.dailyGoal,
            level: widgetData.level,
            questNames: widgetData.questNames,
            questCompletions: updatedCompletions,
            lastUpdated: Date()
        )

        CompleteHabitIntent.writeWidgetData(updatedData)
        WidgetCenter.shared.reloadAllTimelines()

        let habitName = widgetData.questNames[habitIndex]
        logger.info("CompleteHabitFromWidgetIntent: Marked '\(habitName)' complete via widget")

        return .result()
    }
}
