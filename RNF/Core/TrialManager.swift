import Foundation
import os

/// Manages the 14-day Pro trial for new users.
///
/// Activation: On first app launch (no credit card required).
/// Trial duration: 14 days.
/// Expiry banner: Shown from Day 12 onwards.
/// Post-expiry: Soft paywall, features locked, data preserved.
@MainActor
final class TrialManager: ObservableObject {

    // MARK: - Published State

    @Published private(set) var isTrialActive: Bool = false
    @Published private(set) var trialEndDate: Date?
    @Published private(set) var daysRemaining: Int = 0
    @Published private(set) var shouldShowExpiryBanner: Bool = false

    // MARK: - Constants

    static let trialDurationDays = 14
    static let expiryBannerStartDay = 12

    // MARK: - Private

    private static let logger = Logger(subsystem: "com.rnf.app", category: "trial")
    private let trialEndDateKey = "rnf_trial_end_date"
    private let trialActivatedKey = "rnf_trial_activated"
    private let defaults: UserDefaults

    // MARK: - Initialization

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadTrialState()
    }

    // MARK: - Trial Activation

    /// Activates the 14-day trial. No-op if trial was already activated.
    func activateTrialIfNeeded() {
        guard !defaults.bool(forKey: trialActivatedKey) else {
            Self.logger.info("Trial already activated, skipping")
            return
        }

        let endDate = Calendar.current.date(
            byAdding: .day,
            value: Self.trialDurationDays,
            to: Date()
        ) ?? Date().addingTimeInterval(TimeInterval(Self.trialDurationDays * 86400))

        defaults.set(true, forKey: trialActivatedKey)
        defaults.set(endDate, forKey: trialEndDateKey)

        trialEndDate = endDate
        isTrialActive = true
        updateDaysRemaining()

        Self.logger.info("Trial activated. End date: \(endDate)")
    }

    // MARK: - Trial State

    /// Returns true if the user has ever activated a trial.
    var hasActivatedTrial: Bool {
        defaults.bool(forKey: trialActivatedKey)
    }

    /// Returns true if the trial has expired.
    var isTrialExpired: Bool {
        guard let endDate = trialEndDate else { return false }
        return Date() >= endDate
    }

    /// Returns the day number in the trial (1-14).
    var currentTrialDay: Int {
        guard let endDate = trialEndDate else { return 0 }
        let totalDays = Self.trialDurationDays
        let remaining = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: endDate)
        ).day ?? 0
        return max(1, totalDays - remaining)
    }

    // MARK: - Expiry Banner Logic

    /// Determines whether the expiry banner should be shown.
    /// Shows from Day 12 onwards (3 days before expiry).
    var bannerMessage: String? {
        guard isTrialActive, !isTrialExpired else { return nil }

        let day = currentTrialDay

        switch day {
        case 12:
            return "3 days left of your Pro trial. Your skill tree, multipliers, and auto-freezes pause soon."
        case 13:
            return "Tomorrow your Pro features pause. Keep your progress with RNF Pro."
        case 14:
            return "Last day to keep your Pro features active."
        default:
            return nil
        }
    }

    /// Provides contextual messaging based on trial progress.
    var trialStatusMessage: String? {
        guard hasActivatedTrial else { return nil }

        if isTrialExpired {
            return "Your Pro trial has ended. Upgrade to keep full access."
        }

        let day = currentTrialDay

        switch day {
        case 7:
            return "You've been using Pro features for a week. Here's what you've unlocked."
        case 10:
            return "4 days left of your Pro trial."
        default:
            return nil
        }
    }

    // MARK: - Entitlement Integration

    /// Returns true if the user should have Pro access via trial.
    /// Call this in conjunction with SubscriptionManager.hasProAccess.
    var hasTrialProAccess: Bool {
        isTrialActive && !isTrialExpired
    }

    // MARK: - Refresh

    /// Refreshes trial state (call on app foreground).
    func refresh() {
        loadTrialState()
    }

    // MARK: - Private

    private func loadTrialState() {
        guard defaults.bool(forKey: trialActivatedKey) else {
            isTrialActive = false
            trialEndDate = nil
            daysRemaining = 0
            shouldShowExpiryBanner = false
            return
        }

        guard let endDate = defaults.object(forKey: trialEndDateKey) as? Date else {
            isTrialActive = false
            trialEndDate = nil
            daysRemaining = 0
            shouldShowExpiryBanner = false
            return
        }

        trialEndDate = endDate
        isTrialActive = Date() < endDate
        updateDaysRemaining()
    }

    private func updateDaysRemaining() {
        guard let endDate = trialEndDate else {
            daysRemaining = 0
            shouldShowExpiryBanner = false
            return
        }

        let remaining = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: endDate)
        ).day ?? 0

        daysRemaining = max(0, remaining)

        // Show expiry banner from Day 12 (i.e., 3 or fewer days remaining)
        let bannerThreshold = Self.trialDurationDays - Self.expiryBannerStartDay + 1
        shouldShowExpiryBanner = isTrialActive && daysRemaining <= bannerThreshold && daysRemaining > 0
    }
}
