import Foundation
import os

// MARK: - P28-INC-09/10/11/12/13/14: Adaptive Difficulty Mode

/// Adaptive mode reduces pressure for users who need a gentler experience.
/// - Max 2 habits/day (P28-INC-09)
/// - Shorter workout durations: 5 or 10 minutes (P28-INC-10)
/// - 2 Forge tokens/month instead of standard rate (P28-INC-11)
/// - 1+ completion counts as a streak day (P28-INC-12)
/// - More frequent micro-rewards (P28-INC-13)
/// - Reduced XP thresholds for level-ups (P28-INC-14)
@MainActor
final class AdaptiveDifficultyMode: ObservableObject {

    // MARK: - Storage Keys

    private static let enabledKey = "rnf_adaptive_mode_enabled"
    private static let dailyHabitLimitKey = "rnf_adaptive_habit_limit"
    private static let workoutDurationKey = "rnf_adaptive_workout_minutes"
    private static let monthlyTokenLimitKey = "rnf_adaptive_monthly_tokens"
    private static let streakThresholdKey = "rnf_adaptive_streak_threshold"

    // MARK: - Published State

    @Published private(set) var isEnabled: Bool
    @Published private(set) var dailyHabitLimit: Int
    @Published private(set) var workoutDurationMinutes: Int
    @Published private(set) var monthlyTokenLimit: Int
    @Published private(set) var streakCompletionThreshold: Int

    // MARK: - Constants

    static let defaultDailyHabitLimit = 2
    static let defaultWorkoutMinutes = 5
    static let extendedWorkoutMinutes = 10
    static let defaultMonthlyTokens = 2
    static let defaultStreakThreshold = 1
    static let microRewardInterval = 1   // Reward after every completion
    static let xpMultiplier: Double = 0.7 // 30% less XP needed per level

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard
        self.isEnabled = defaults.bool(forKey: Self.enabledKey)
        self.dailyHabitLimit = defaults.object(forKey: Self.dailyHabitLimitKey) as? Int
            ?? Self.defaultDailyHabitLimit
        self.workoutDurationMinutes = defaults.object(forKey: Self.workoutDurationKey) as? Int
            ?? Self.defaultWorkoutMinutes
        self.monthlyTokenLimit = defaults.object(forKey: Self.monthlyTokenLimitKey) as? Int
            ?? Self.defaultMonthlyTokens
        self.streakCompletionThreshold = defaults.object(forKey: Self.streakThresholdKey) as? Int
            ?? Self.defaultStreakThreshold
    }

    // MARK: - Enable / Disable

    func enable() {
        isEnabled = true
        dailyHabitLimit = Self.defaultDailyHabitLimit
        workoutDurationMinutes = Self.defaultWorkoutMinutes
        monthlyTokenLimit = Self.defaultMonthlyTokens
        streakCompletionThreshold = Self.defaultStreakThreshold
        persist()
        RNFLogger.engagement.info("Adaptive difficulty mode enabled")
    }

    func disable() {
        isEnabled = false
        persist()
        RNFLogger.engagement.info("Adaptive difficulty mode disabled")
    }

    // MARK: - Configuration

    func setWorkoutDuration(_ minutes: Int) {
        guard minutes == Self.defaultWorkoutMinutes || minutes == Self.extendedWorkoutMinutes else {
            return
        }
        workoutDurationMinutes = minutes
        persist()
    }

    // MARK: - Streak Calculation (P28-INC-12)

    /// In adaptive mode, completing 1+ habits counts as a streak day.
    /// In standard mode, the full daily goal must be met.
    func shouldCountAsStreakDay(completions: Int, dailyGoal: Int) -> Bool {
        if isEnabled {
            return completions >= streakCompletionThreshold
        }
        return completions >= dailyGoal
    }

    // MARK: - Daily Goal (P28-INC-09)

    /// Returns the effective daily goal (capped in adaptive mode).
    func effectiveDailyGoal(requestedGoal: Int) -> Int {
        if isEnabled {
            return min(requestedGoal, dailyHabitLimit)
        }
        return requestedGoal
    }

    // MARK: - Workout Duration (P28-INC-10)

    /// Returns available workout durations for the mode.
    var availableWorkoutDurations: [Int] {
        if isEnabled {
            return [Self.defaultWorkoutMinutes, Self.extendedWorkoutMinutes]
        }
        return [5, 10, 15, 20, 30, 45, 60]
    }

    // MARK: - Token Earning (P28-INC-11)

    /// Whether the user can still earn tokens this month.
    func canEarnToken(tokensEarnedThisMonth: Int) -> Bool {
        if isEnabled {
            return tokensEarnedThisMonth < monthlyTokenLimit
        }
        return true // Standard mode has no monthly cap here
    }

    // MARK: - Micro-Rewards (P28-INC-13)

    /// In adaptive mode, reward after every single completion.
    /// Standard mode rewards at specific intervals (every 3).
    func shouldTriggerMicroReward(completionCount: Int) -> Bool {
        if isEnabled {
            return completionCount > 0 && completionCount % Self.microRewardInterval == 0
        }
        return completionCount > 0 && completionCount % 3 == 0
    }

    /// Micro-reward types available in adaptive mode.
    enum MicroReward: String, CaseIterable {
        case encouragement   // Motivational message
        case xpBonus         // Small XP bonus (+5)
        case streakShield    // Temporary streak protection reminder
        case confetti        // Visual celebration
    }

    /// Returns the reward type for a given completion count.
    func microRewardType(for completionCount: Int) -> MicroReward {
        let index = (completionCount - 1) % MicroReward.allCases.count
        return MicroReward.allCases[index]
    }

    // MARK: - XP Scaling (P28-INC-14)

    /// Adjusts XP-to-next-level threshold for adaptive mode.
    func adjustedXPToNextLevel(standardXP: Int) -> Int {
        if isEnabled {
            return Int(Double(standardXP) * Self.xpMultiplier)
        }
        return standardXP
    }

    // MARK: - Persistence

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(isEnabled, forKey: Self.enabledKey)
        defaults.set(dailyHabitLimit, forKey: Self.dailyHabitLimitKey)
        defaults.set(workoutDurationMinutes, forKey: Self.workoutDurationKey)
        defaults.set(monthlyTokenLimit, forKey: Self.monthlyTokenLimitKey)
        defaults.set(streakCompletionThreshold, forKey: Self.streakThresholdKey)
    }
}

// RNFLogger.engagement defined in Core/RNFLogger.swift
