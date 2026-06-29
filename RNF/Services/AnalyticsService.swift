import Foundation
import os

final class AnalyticsService {

    enum EventName: String {
        case appOpened = "app_opened"
        case habitCompleted = "habit_completed"
        case dailyGoalCompleted = "daily_goal_completed"
        case workoutCompleted = "workout_completed"
        case readingCompleted = "reading_completed"
        case levelUp = "level_up"
        case streakIncreased = "streak_increased"
        case forgivenessUsed = "forgiveness_used"
        case challengeStarted = "challenge_started"
        case challengeCompleted = "challenge_completed"
        case weeklyQuestUnlocked = "weekly_quest_unlocked"
        case skillTreeOpened = "skill_tree_opened"
        case skillTreeNodeUnlocked = "skill_tree_node_unlocked"
        case evolutionMilestoneReached = "evolution_milestone_reached"
        case perkBonusApplied = "perk_bonus_applied"
        case streakProtectionApplied = "streak_protection_applied"
        case notificationOpened = "notification_opened"
        case trialStarted = "trial_started"
        case subscriptionStarted = "subscription_started"
        case subscriptionCanceled = "subscription_canceled"
    }

    private let supabase: SupabaseService
    private static let logger = Logger(subsystem: "com.rnf.app", category: "Analytics")

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    /// GAP 7: Wire analytics backend — persist events to Supabase analytics_events table.
    /// Spec: RNF_METRICS_SYSTEM.md — Events must be tracked: app_opened, habit_completed, level_up, etc.
    func trackEvent(
        name: String,
        properties: [String: String] = [:]
    ) async {
        let event = AnalyticsEvent(
            id: UUID(),
            event_name: name,
            properties: properties,
            created_at: Date()
        )

        do {
            try await supabase.client
                .from("analytics_events")
                .insert(event)
                .execute()
        } catch {
            Self.logger.warning("Analytics event '\(name)' failed to persist: \(error.localizedDescription)")
        }
    }

    func trackEvent(
        _ eventName: EventName,
        properties: [String: String] = [:]
    ) async {
        await trackEvent(
            name: eventName.rawValue,
            properties: properties
        )
    }
}

private struct AnalyticsEvent: Encodable {
    let id: UUID
    let event_name: String
    let properties: [String: String]
    let created_at: Date
}
