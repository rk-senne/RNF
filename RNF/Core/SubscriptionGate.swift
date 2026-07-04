import Foundation

/// Enforces free tier limits and gates Pro-only features.
///
/// Free tier constraints (from SPEC_MONETIZATION):
/// - Level capped at 10
/// - Maximum 3 habits
/// - Skill tree locked
/// - No seasonal arcs, boss battles, focus timer, reading profile
/// - 1 forgiveness token per 30 days
/// - Basic weekly summary only
/// - First 10 achievements only
@MainActor
enum SubscriptionGate {

    // MARK: - Free Tier Limits

    static let freeLevelCap = 10
    static let freeHabitLimit = 3
    static let freeAchievementLimit = 10
    static let freeForgiveTokensPerMonth = 1
    static let freeNotificationsPerDay = 2

    // MARK: - Pro-Only Features

    enum ProFeature: String, CaseIterable {
        case unlimitedHabits
        case skillTree
        case seasonalArcs
        case bossChallenge
        case streakMultipliers
        case focusTimer
        case readingProfile
        case weeklyInsights
        case disciplineCard
        case dataExport
        case leaderboardLeagues
        case evolvingUI
        case customNotifications
        case autoStreakFreeze
    }

    // MARK: - Access Checks

    /// Returns true if the user can access the given Pro feature.
    static func canAccess(
        _ feature: ProFeature,
        subscriptionManager: SubscriptionManager
    ) -> Bool {
        subscriptionManager.hasProAccess
    }

    /// Returns true if user can level up beyond free cap.
    static func canLevelUp(
        currentLevel: Int,
        subscriptionManager: SubscriptionManager
    ) -> Bool {
        if subscriptionManager.hasProAccess { return true }
        return currentLevel < freeLevelCap
    }

    /// Returns the effective level, capped for free users.
    static func effectiveLevel(
        rawLevel: Int,
        subscriptionManager: SubscriptionManager
    ) -> Int {
        if subscriptionManager.hasProAccess { return rawLevel }
        return min(rawLevel, freeLevelCap)
    }

    /// Returns true if the user can add another habit.
    static func canAddHabit(
        currentHabitCount: Int,
        subscriptionManager: SubscriptionManager
    ) -> Bool {
        if subscriptionManager.hasProAccess { return true }
        return currentHabitCount < freeHabitLimit
    }

    /// Returns the maximum number of habits allowed for the user's tier.
    static func habitLimit(subscriptionManager: SubscriptionManager) -> Int? {
        if subscriptionManager.hasProAccess { return nil } // unlimited
        return freeHabitLimit
    }

    /// Returns true if the skill tree is accessible.
    static func canAccessSkillTree(subscriptionManager: SubscriptionManager) -> Bool {
        subscriptionManager.hasProAccess
    }

    /// Returns the number of forgiveness tokens available per month for the tier.
    static func forgiveTokensPerMonth(subscriptionManager: SubscriptionManager) -> Int {
        if subscriptionManager.hasProAccess { return 3 }
        return freeForgiveTokensPerMonth
    }

    /// Returns the number of daily notifications allowed for the tier.
    static func notificationsPerDay(subscriptionManager: SubscriptionManager) -> Int {
        if subscriptionManager.hasProAccess { return 10 } // effectively unlimited
        return freeNotificationsPerDay
    }

    /// Returns the achievement count limit for the tier.
    static func achievementLimit(subscriptionManager: SubscriptionManager) -> Int? {
        if subscriptionManager.hasProAccess { return nil }
        return freeAchievementLimit
    }

    // MARK: - Gate Result

    /// Provides a structured result for gate checks, useful for UI decisions.
    struct GateResult {
        let allowed: Bool
        let reason: GateReason?

        static let allowed = GateResult(allowed: true, reason: nil)

        static func blocked(_ reason: GateReason) -> GateResult {
            GateResult(allowed: false, reason: reason)
        }
    }

    enum GateReason {
        case levelCapped
        case habitLimitReached
        case proFeatureRequired
        case skillTreeLocked

        var message: String {
            switch self {
            case .levelCapped:
                return "Level capped at \(SubscriptionGate.freeLevelCap) on Free tier"
            case .habitLimitReached:
                return "Free tier limited to \(SubscriptionGate.freeHabitLimit) habits"
            case .proFeatureRequired:
                return "This feature requires RNF Pro"
            case .skillTreeLocked:
                return "Skill tree is a Pro feature"
            }
        }
    }

    /// Comprehensive gate check with reason.
    static func checkAccess(
        feature: ProFeature,
        subscriptionManager: SubscriptionManager
    ) -> GateResult {
        if subscriptionManager.hasProAccess {
            return .allowed
        }

        switch feature {
        case .skillTree:
            return .blocked(.skillTreeLocked)
        default:
            return .blocked(.proFeatureRequired)
        }
    }

    /// Gate check for adding a habit.
    static func checkAddHabit(
        currentCount: Int,
        subscriptionManager: SubscriptionManager
    ) -> GateResult {
        if subscriptionManager.hasProAccess {
            return .allowed
        }

        if currentCount >= freeHabitLimit {
            return .blocked(.habitLimitReached)
        }

        return .allowed
    }

    /// Gate check for leveling up.
    static func checkLevelUp(
        currentLevel: Int,
        subscriptionManager: SubscriptionManager
    ) -> GateResult {
        if subscriptionManager.hasProAccess {
            return .allowed
        }

        if currentLevel >= freeLevelCap {
            return .blocked(.levelCapped)
        }

        return .allowed
    }
}
