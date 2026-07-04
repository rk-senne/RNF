import Foundation
import os

// MARK: - P25-INT-17/18/19/20/21/22: Engagement State Manager

/// Manages user engagement lifecycle through 5 states.
/// Enforces push notification safeguards.
@MainActor
final class EngagementStateManager: ObservableObject {

    // MARK: - Types

    enum EngagementState: String, Codable, CaseIterable {
        case engaged       // Active, completing habits regularly
        case atRisk        // Early signs of drop-off
        case drifting      // Moderate disengagement
        case lapsed        // Extended absence
        case churned       // Long-term inactive — do not contact
    }

    struct EngagementSnapshot: Codable {
        let state: EngagementState
        let transitionedAt: Date
        let appOpensLast7Days: Int
        let completionRateLast7Days: Double
        let daysSinceLastOpen: Int
    }

    struct PushRecord: Codable {
        let sentAt: Date
        let type: String
    }

    // MARK: - Constants

    /// Transition thresholds
    private static let engagedMinOpens = 4         // 4+ opens per 7 days
    private static let engagedMinRate: Double = 0.6
    private static let atRiskMaxOpens = 3          // 2-3 opens per 7 days
    private static let atRiskMinRate: Double = 0.3
    private static let driftingMaxDaysAway = 7     // 4-7 days without open
    private static let lapsedMinDaysAway = 8       // 8-14 days
    private static let churnedMinDaysAway = 15     // 15+ days

    /// Push safeguards
    private static let maxPushPer30Days = 5
    private static let pushWindowDays = 30

    // MARK: - State

    @Published private(set) var currentState: EngagementState = .engaged
    @Published private(set) var snapshot: EngagementSnapshot?

    // MARK: - Dependencies

    private static let logger = Logger(subsystem: "com.rnf.app", category: "engagement_state")

    // MARK: - Cache Keys

    private static let stateKey = "rnf_engagement_state"
    private static let snapshotKey = "rnf_engagement_snapshot"
    private static let pushHistoryKey = "rnf_push_history"

    // MARK: - Init

    init() {
        loadCachedState()
    }

    // MARK: - Public API

    /// Evaluates the user's engagement based on recent activity metrics.
    /// Call this daily or on app foreground.
    func evaluate(appOpensLast7Days: Int, completionRateLast7Days: Double, daysSinceLastOpen: Int) {
        let previousState = currentState
        let newState = computeState(
            appOpens: appOpensLast7Days,
            completionRate: completionRateLast7Days,
            daysSinceLastOpen: daysSinceLastOpen
        )

        let newSnapshot = EngagementSnapshot(
            state: newState,
            transitionedAt: newState != previousState ? Date() : (snapshot?.transitionedAt ?? Date()),
            appOpensLast7Days: appOpensLast7Days,
            completionRateLast7Days: completionRateLast7Days,
            daysSinceLastOpen: daysSinceLastOpen
        )

        if newState != previousState {
            Self.logger.info("Engagement state transition: \(previousState.rawValue) → \(newState.rawValue)")
        }

        currentState = newState
        snapshot = newSnapshot
        cacheState()
    }

    /// Whether a push notification is allowed for the current state.
    /// Returns false if:
    /// - User is Churned (never send after churn)
    /// - Push limit exceeded (max 5 per 30 days)
    func canSendPush() -> Bool {
        // Never push to churned users
        guard currentState != .churned else {
            Self.logger.info("Push blocked: user is in Churned state")
            return false
        }

        // Check push frequency limit
        let recentPushes = pushesInWindow()
        guard recentPushes < Self.maxPushPer30Days else {
            Self.logger.info("Push blocked: limit reached (\(recentPushes)/\(Self.maxPushPer30Days) in 30 days)")
            return false
        }

        return true
    }

    /// Records that a push was sent. Call after successfully scheduling.
    func recordPushSent(type: String) {
        var history = loadPushHistory()
        history.append(PushRecord(sentAt: Date(), type: type))

        // Prune old entries beyond 30 days
        let cutoff = Calendar.current.date(byAdding: .day, value: -Self.pushWindowDays, to: Date()) ?? Date()
        history = history.filter { $0.sentAt >= cutoff }

        savePushHistory(history)
        Self.logger.info("Push recorded: \(type) (total in window: \(history.count))")
    }

    /// Returns remaining push budget in current 30-day window.
    var remainingPushBudget: Int {
        max(0, Self.maxPushPer30Days - pushesInWindow())
    }

    /// Returns the suggested notification strategy for the current state.
    var notificationStrategy: String {
        switch currentState {
        case .engaged:
            return "Celebration & progress milestones only"
        case .atRisk:
            return "Gentle reminders with streak emphasis"
        case .drifting:
            return "Re-engagement with missed content highlights"
        case .lapsed:
            return "Win-back with easy challenge offer"
        case .churned:
            return "No notifications — respect the user's absence"
        }
    }

    // MARK: - State Computation

    private func computeState(appOpens: Int, completionRate: Double, daysSinceLastOpen: Int) -> EngagementState {
        // Churned: 15+ days without opening
        if daysSinceLastOpen >= Self.churnedMinDaysAway {
            return .churned
        }

        // Lapsed: 8-14 days without opening
        if daysSinceLastOpen >= Self.lapsedMinDaysAway {
            return .lapsed
        }

        // Drifting: 4-7 days without opening
        if daysSinceLastOpen >= 4 {
            return .drifting
        }

        // Engaged: 4+ opens AND 60%+ completion rate
        if appOpens >= Self.engagedMinOpens && completionRate >= Self.engagedMinRate {
            return .engaged
        }

        // AtRisk: lower activity but still opening
        if appOpens >= 1 && (appOpens <= Self.atRiskMaxOpens || completionRate < Self.engagedMinRate) {
            return .atRisk
        }

        // Default to engaged if opening the app at all
        return .engaged
    }

    // MARK: - Push History

    private func pushesInWindow() -> Int {
        let history = loadPushHistory()
        let cutoff = Calendar.current.date(byAdding: .day, value: -Self.pushWindowDays, to: Date()) ?? Date()
        return history.filter { $0.sentAt >= cutoff }.count
    }

    private func loadPushHistory() -> [PushRecord] {
        guard let data = UserDefaults.standard.data(forKey: Self.pushHistoryKey) else { return [] }
        return (try? JSONDecoder().decode([PushRecord].self, from: data)) ?? []
    }

    private func savePushHistory(_ history: [PushRecord]) {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: Self.pushHistoryKey)
    }

    // MARK: - Caching

    private func loadCachedState() {
        if let rawState = UserDefaults.standard.string(forKey: Self.stateKey),
           let state = EngagementState(rawValue: rawState) {
            currentState = state
        }

        if let data = UserDefaults.standard.data(forKey: Self.snapshotKey),
           let cached = try? JSONDecoder().decode(EngagementSnapshot.self, from: data) {
            snapshot = cached
        }
    }

    private func cacheState() {
        UserDefaults.standard.set(currentState.rawValue, forKey: Self.stateKey)

        if let snap = snapshot, let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: Self.snapshotKey)
        }
    }

    // MARK: - Static Testable APIs

    /// Computes the engagement state from raw inputs without side effects.
    /// - Parameters:
    ///   - currentState: The previous engagement state.
    ///   - lastOpenDate: The date the app was last opened.
    ///   - recentCompletionRate: Completion rate for the recent period (0.0 - 1.0).
    ///   - consecutiveZeroCompletionDays: Number of days with zero completions while app was opened.
    ///   - now: Current date (for testability).
    /// - Returns: The new engagement state.
    static func computeState(
        currentState: EngagementState,
        lastOpenDate: Date,
        recentCompletionRate: Double,
        consecutiveZeroCompletionDays: Int = 0,
        now: Date = Date()
    ) -> EngagementState {
        let daysSinceOpen = daysSinceLastOpen(from: lastOpenDate, to: now)

        // Recovery: user returned (opened today with completions)
        if daysSinceOpen == 0 && recentCompletionRate > 0 && currentState != .engaged {
            return .engaged
        }

        // CHURNED: 7+ days without opening
        if daysSinceOpen >= 7 {
            return .churned
        }

        // LAPSED: 4-6 days without opening
        if daysSinceOpen >= 4 {
            return .lapsed
        }

        // DRIFTING: 2-3 days without opening
        if daysSinceOpen >= 2 {
            return .drifting
        }

        // AT_RISK: 1 day without opening OR 2+ days with zero completions while opened
        if daysSinceOpen >= 1 || consecutiveZeroCompletionDays >= 2 {
            return .atRisk
        }

        // Default: ENGAGED
        return .engaged
    }

    /// Whether a push is allowed given the safeguard constraints.
    /// - Parameters:
    ///   - pushesSent30Days: Number of pushes sent in the last 30 days.
    ///   - lastPushDate: Date of the last push sent (nil = never sent).
    ///   - now: Current date.
    /// - Returns: Whether a push can be sent.
    static func canSendPush(pushesSent30Days: Int, lastPushDate: Date?, now: Date = Date()) -> Bool {
        // Check 30-day limit (max 5)
        guard pushesSent30Days < maxPushPer30Days else { return false }

        // Check 48-hour cooldown
        if let lastPush = lastPushDate {
            let hoursSinceLastPush = now.timeIntervalSince(lastPush) / 3600.0
            guard hoursSinceLastPush >= 48.0 else { return false }
        }

        return true
    }

    /// Whether pushes should be sent for a given state.
    static func shouldSendPush(forState state: EngagementState) -> Bool {
        switch state {
        case .engaged, .churned:
            return false
        case .atRisk, .drifting, .lapsed:
            return true
        }
    }

    /// Computes days between two dates.
    static func daysSinceLastOpen(from lastOpen: Date, to now: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastOpen), to: calendar.startOfDay(for: now))
        return max(0, components.day ?? 0)
    }
}
