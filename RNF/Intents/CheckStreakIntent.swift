import AppIntents
import Foundation
import os

// MARK: - P26-APL-04: Check Streak Intent

/// Returns the current streak count and tier as a spoken Siri result.
/// Does not open the app — purely informational.
struct CheckStreakIntent: AppIntent {

    static var title: LocalizedStringResource = "Check Streak"
    static var description = IntentDescription("Check your current streak count and tier in RNF")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Int> {
        let logger = Logger(subsystem: "com.rnf.app", category: "intents")

        guard let widgetData = CompleteHabitIntent.loadWidgetData() else {
            logger.error("CheckStreakIntent: Could not load widget data")
            return .result(
                value: 0,
                dialog: "I couldn't load your streak data. Open RNF to sync."
            )
        }

        let streak = widgetData.streakCount
        let tier = StreakTierSystem.tier(for: streak)
        let tierIcon = StreakTierSystem.icon(for: tier)
        let tierName = tier.rawValue

        logger.info("CheckStreakIntent: Streak=\(streak), Tier=\(tierName)")

        let dialog: String
        if streak == 0 {
            dialog = "No active streak yet. Complete today's habits to start one! \(tierIcon)"
        } else if streak == 1 {
            dialog = "You're on day 1! \(tierIcon) \(tierName) tier. Every journey starts with a single step."
        } else {
            let progress = widgetData.dailyCompleted
            let goal = widgetData.dailyGoal
            let todayStatus = progress >= goal
                ? "All habits done today!"
                : "\(progress)/\(goal) habits completed today."

            dialog = "You're on a \(streak)-day streak! \(tierIcon) \(tierName) tier. \(todayStatus)"
        }

        return .result(value: streak, dialog: "\(dialog)")
    }
}
