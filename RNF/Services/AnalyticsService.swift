import Foundation

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
        case notificationOpened = "notification_opened"
        case trialStarted = "trial_started"
        case subscriptionStarted = "subscription_started"
        case subscriptionCanceled = "subscription_canceled"
    }

    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func trackEvent(
        name: String,
        properties: [String: String] = [:]
    ) async {
        _ = supabase
        _ = name
        _ = properties
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
