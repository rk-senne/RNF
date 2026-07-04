import Foundation
import os

// MARK: - P25-INT-06/07/08/09/10/11: Difficulty Advisor

/// Analyzes trailing completion rates and suggests difficulty adjustments.
/// Enforces cooldown rules to prevent premature changes.
@MainActor
final class DifficultyAdvisor {

    // MARK: - Types

    enum Suggestion: String, Codable, Equatable {
        case suggestIncrease = "suggest_increase"
        case suggestDecrease = "suggest_decrease"
        case maintain
    }

    struct DailyCompletion: Codable {
        let date: Date
        let completed: Int
        let target: Int
    }

    struct AdjustmentRecord: Codable {
        let id: UUID
        let direction: String  // "increase" or "decrease"
        let previousTarget: Int
        let newTarget: Int
        let reason: String
        let appliedAt: Date
    }

    struct AdvisorResult: Equatable {
        let suggestion: Suggestion
        let completionRate: Double
        let consecutiveDays: Int
        let reason: String
    }

    // MARK: - Constants

    private static let trailingWindowDays = 7
    private static let increaseThreshold: Double = 0.90
    private static let decreaseThreshold: Double = 0.50
    private static let increaseDaysRequired = 7
    private static let decreaseDaysRequired = 3
    private static let cooldownBeforeIncreaseDays = 14
    private static let cooldownBeforeDecreaseDays = 7

    // MARK: - Dependencies

    private let supabase: SupabaseService
    private static let logger = Logger(subsystem: "com.rnf.app", category: "difficulty_advisor")

    // MARK: - Cache

    private static let lastAdjustmentKey = "rnf_last_difficulty_adjustment"
    private static let accountCreatedKey = "rnf_account_created_date"

    // MARK: - Init

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    // MARK: - Public API

    /// Analyzes trailing 7-day completion data and returns a suggestion.
    func analyze(completions: [DailyCompletion], accountCreatedAt: Date) -> AdvisorResult {
        let calendar = Calendar.current
        let now = Date()

        // Sort by date descending and take last 7 days
        let recentCompletions = completions
            .filter { calendar.dateComponents([.day], from: $0.date, to: now).day ?? 999 < Self.trailingWindowDays }
            .sorted { $0.date > $1.date }

        guard !recentCompletions.isEmpty else {
            return AdvisorResult(
                suggestion: .maintain,
                completionRate: 0,
                consecutiveDays: 0,
                reason: "Insufficient data for analysis"
            )
        }

        // Calculate daily rates
        let dailyRates = recentCompletions.map { entry -> Double in
            guard entry.target > 0 else { return 0 }
            return Double(entry.completed) / Double(entry.target)
        }

        let overallRate = dailyRates.reduce(0, +) / Double(dailyRates.count)

        // Check for increase suggestion: >90% for 7 consecutive days
        let highDays = consecutiveDaysAboveThreshold(dailyRates, threshold: Self.increaseThreshold)
        if highDays >= Self.increaseDaysRequired {
            if canSuggestIncrease(accountCreatedAt: accountCreatedAt) {
                return AdvisorResult(
                    suggestion: .suggestIncrease,
                    completionRate: overallRate,
                    consecutiveDays: highDays,
                    reason: "Completion rate above 90% for \(highDays) consecutive days"
                )
            } else {
                return AdvisorResult(
                    suggestion: .maintain,
                    completionRate: overallRate,
                    consecutiveDays: highDays,
                    reason: "In cooldown period — increase not yet available"
                )
            }
        }

        // Check for decrease suggestion: <50% for 3 consecutive days
        let lowDays = consecutiveDaysBelowThreshold(dailyRates, threshold: Self.decreaseThreshold)
        if lowDays >= Self.decreaseDaysRequired {
            if canSuggestDecrease(accountCreatedAt: accountCreatedAt) {
                return AdvisorResult(
                    suggestion: .suggestDecrease,
                    completionRate: overallRate,
                    consecutiveDays: lowDays,
                    reason: "Completion rate below 50% for \(lowDays) consecutive days"
                )
            } else {
                return AdvisorResult(
                    suggestion: .maintain,
                    completionRate: overallRate,
                    consecutiveDays: lowDays,
                    reason: "In cooldown period — decrease not yet available"
                )
            }
        }

        return AdvisorResult(
            suggestion: .maintain,
            completionRate: overallRate,
            consecutiveDays: 0,
            reason: "Performance is within normal range"
        )
    }

    /// Records a difficulty adjustment to Supabase and local cache.
    func recordAdjustment(
        direction: String,
        previousTarget: Int,
        newTarget: Int,
        reason: String
    ) async {
        let record = AdjustmentRecord(
            id: UUID(),
            direction: direction,
            previousTarget: previousTarget,
            newTarget: newTarget,
            reason: reason,
            appliedAt: Date()
        )

        // Cache locally
        cacheLastAdjustment(record)

        // Persist to Supabase
        guard let client = supabase.client else { return }

        do {
            try await client
                .from("difficulty_adjustments")
                .insert(record)
                .execute()
            Self.logger.info("Difficulty adjustment recorded: \(direction) \(previousTarget) → \(newTarget)")
        } catch {
            Self.logger.warning("Failed to persist difficulty adjustment: \(error.localizedDescription)")
        }
    }

    /// Computes trailing 7-day completion rate as a percentage.
    func trailingCompletionRate(completions: [DailyCompletion]) -> Double {
        let calendar = Calendar.current
        let now = Date()

        let recent = completions.filter {
            calendar.dateComponents([.day], from: $0.date, to: now).day ?? 999 < Self.trailingWindowDays
        }

        guard !recent.isEmpty else { return 0 }

        let totalCompleted = recent.reduce(0) { $0 + $1.completed }
        let totalTarget = recent.reduce(0) { $0 + $1.target }

        guard totalTarget > 0 else { return 0 }
        return Double(totalCompleted) / Double(totalTarget)
    }

    // MARK: - Cooldown Rules

    /// No increase suggestion during first 14 days of account or within 14 days of last adjustment.
    func canSuggestIncrease(accountCreatedAt: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        // Check account age
        let accountAge = calendar.dateComponents([.day], from: accountCreatedAt, to: now).day ?? 0
        guard accountAge >= Self.cooldownBeforeIncreaseDays else { return false }

        // Check last adjustment cooldown
        if let lastAdjustment = cachedLastAdjustment() {
            let daysSinceAdjustment = calendar.dateComponents([.day], from: lastAdjustment.appliedAt, to: now).day ?? 0
            guard daysSinceAdjustment >= Self.cooldownBeforeIncreaseDays else { return false }
        }

        return true
    }

    /// No decrease suggestion during first 7 days of account or within 7 days of last adjustment.
    func canSuggestDecrease(accountCreatedAt: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        // Check account age
        let accountAge = calendar.dateComponents([.day], from: accountCreatedAt, to: now).day ?? 0
        guard accountAge >= Self.cooldownBeforeDecreaseDays else { return false }

        // Check last adjustment cooldown
        if let lastAdjustment = cachedLastAdjustment() {
            let daysSinceAdjustment = calendar.dateComponents([.day], from: lastAdjustment.appliedAt, to: now).day ?? 0
            guard daysSinceAdjustment >= Self.cooldownBeforeDecreaseDays else { return false }
        }

        return true
    }

    // MARK: - Private Helpers

    private func consecutiveDaysAboveThreshold(_ rates: [Double], threshold: Double) -> Int {
        var count = 0
        for rate in rates {
            if rate >= threshold {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    private func consecutiveDaysBelowThreshold(_ rates: [Double], threshold: Double) -> Int {
        var count = 0
        for rate in rates {
            if rate < threshold {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    // MARK: - Caching

    private func cacheLastAdjustment(_ record: AdjustmentRecord) {
        guard let data = try? JSONEncoder().encode(record) else { return }
        UserDefaults.standard.set(data, forKey: Self.lastAdjustmentKey)
    }

    func cachedLastAdjustment() -> AdjustmentRecord? {
        guard let data = UserDefaults.standard.data(forKey: Self.lastAdjustmentKey) else { return nil }
        return try? JSONDecoder().decode(AdjustmentRecord.self, from: data)
    }

    // MARK: - Static Testable APIs

    /// Suggestion type for tests (simplified).
    enum SuggestionDirection: Equatable {
        case increase
        case decrease
        case none
    }

    /// Goal boundaries.
    static let minimumGoal = 2
    static let maximumGoal = 6

    /// Evaluates the difficulty advisor rules using raw rate arrays.
    /// - Parameters:
    ///   - trailing7DayRates: Daily completion rates for the trailing 7 days.
    ///   - currentGoal: The user's current daily goal count.
    ///   - accountAgeDays: Days since account creation.
    ///   - daysSinceLastDismiss: Days since the user last dismissed a suggestion (nil = no prior dismiss).
    /// - Returns: A suggestion direction or `.none`.
    static func evaluate(
        trailing7DayRates: [Double],
        currentGoal: Int,
        accountAgeDays: Int,
        daysSinceLastDismiss: Int? = nil
    ) -> SuggestionDirection {
        // Require at least 7 days of data
        guard trailing7DayRates.count >= 7 else { return .none }

        // Check cooldown from dismiss (7 days)
        if let daysSinceDismiss = daysSinceLastDismiss, daysSinceDismiss <= 7 {
            return .none
        }

        // Check for increase: >90% for ALL 7 days
        let allAbove90 = trailing7DayRates.prefix(7).allSatisfy { $0 > 0.90 }
        if allAbove90 && currentGoal < maximumGoal && accountAgeDays >= 14 {
            return .increase
        }

        // Check for decrease: last 3 days <50% (consecutive from end)
        let lastThree = Array(trailing7DayRates.suffix(3))
        let allBelow50 = lastThree.allSatisfy { $0 < 0.50 }
        if allBelow50 && currentGoal > minimumGoal && accountAgeDays >= 7 {
            return .decrease
        }

        return .none
    }
}
