import Foundation
import os

// MARK: - P28-INC-15/16/17/18/19: Commitment Stage Manager

/// Manages user commitment lifecycle through progressive stages.
/// - Exploration: No streak pressure, 7-day trial period (P28-INC-15)
/// - Foundation: Gentle streak, 30-day period (P28-INC-16)
/// - Full: Standard RNF experience with all streak/boss mechanics (P28-INC-17)
/// - Auto-upgrade prompts at Day 7 and Day 30 (P28-INC-18/19)
@MainActor
final class CommitmentStageManager: ObservableObject {

    // MARK: - Types

    enum CommitmentStage: String, Codable, CaseIterable {
        case exploration  // Day 1-7: no streak, no penalties
        case foundation   // Day 8-30: gentle streak, forgiving
        case full         // Day 31+: full RNF mechanics

        var displayName: String {
            switch self {
            case .exploration: return "Exploration"
            case .foundation: return "Foundation"
            case .full: return "Full Forge"
            }
        }

        var description: String {
            switch self {
            case .exploration:
                return "No pressure. Try habits freely for 7 days — no streaks, no penalties."
            case .foundation:
                return "Building consistency. Gentle streaks that forgive the occasional miss."
            case .full:
                return "Full RNF experience. Streaks, bosses, and all progression mechanics active."
            }
        }
    }

    struct StageConfiguration: Codable {
        let stage: CommitmentStage
        let streakEnabled: Bool
        let streakForgiving: Bool   // Allows 1 miss without breaking
        let bossesEnabled: Bool
        let penaltiesEnabled: Bool
        let durationDays: Int?      // nil = permanent
    }

    // MARK: - Storage Keys

    private static let stageKey = "rnf_commitment_stage"
    private static let startDateKey = "rnf_commitment_start_date"
    private static let lastUpgradePromptKey = "rnf_commitment_last_prompt_day"
    private static let declinedUpgradeKey = "rnf_commitment_declined_upgrade"

    // MARK: - Published State

    @Published private(set) var currentStage: CommitmentStage
    @Published private(set) var startDate: Date
    @Published var showUpgradePrompt: Bool = false
    @Published private(set) var suggestedNextStage: CommitmentStage?

    // MARK: - Constants

    static let explorationDays = 7
    static let foundationDays = 30

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard

        if let raw = defaults.string(forKey: Self.stageKey),
           let stage = CommitmentStage(rawValue: raw) {
            self.currentStage = stage
        } else {
            self.currentStage = .exploration
        }

        if let date = defaults.object(forKey: Self.startDateKey) as? Date {
            self.startDate = date
        } else {
            let now = Date()
            self.startDate = now
            defaults.set(now, forKey: Self.startDateKey)
        }
    }

    // MARK: - Stage Configuration

    func configuration(for stage: CommitmentStage) -> StageConfiguration {
        switch stage {
        case .exploration:
            return StageConfiguration(
                stage: .exploration,
                streakEnabled: false,
                streakForgiving: false,
                bossesEnabled: false,
                penaltiesEnabled: false,
                durationDays: Self.explorationDays
            )
        case .foundation:
            return StageConfiguration(
                stage: .foundation,
                streakEnabled: true,
                streakForgiving: true, // 1 miss forgiven
                bossesEnabled: false,
                penaltiesEnabled: false,
                durationDays: Self.foundationDays
            )
        case .full:
            return StageConfiguration(
                stage: .full,
                streakEnabled: true,
                streakForgiving: false,
                bossesEnabled: true,
                penaltiesEnabled: true,
                durationDays: nil
            )
        }
    }

    var currentConfiguration: StageConfiguration {
        configuration(for: currentStage)
    }

    // MARK: - Day Tracking

    var daysSinceStart: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
    }

    // MARK: - Upgrade Check (P28-INC-18/19)

    /// Call daily to check if the user should be prompted to upgrade.
    func checkForUpgradePrompt() {
        let day = daysSinceStart
        let defaults = UserDefaults.standard
        let lastPromptDay = defaults.integer(forKey: Self.lastUpgradePromptKey)
        let declined = defaults.bool(forKey: Self.declinedUpgradeKey)

        // Don't re-prompt if already declined this stage transition
        guard !declined else { return }

        switch currentStage {
        case .exploration:
            // Prompt at Day 7
            if day >= Self.explorationDays && lastPromptDay < Self.explorationDays {
                suggestedNextStage = .foundation
                showUpgradePrompt = true
                defaults.set(day, forKey: Self.lastUpgradePromptKey)
            }
        case .foundation:
            // Prompt at Day 30
            if day >= Self.foundationDays && lastPromptDay < Self.foundationDays {
                suggestedNextStage = .full
                showUpgradePrompt = true
                defaults.set(day, forKey: Self.lastUpgradePromptKey)
            }
        case .full:
            break // No further upgrades
        }
    }

    // MARK: - Stage Transitions

    /// Accept the suggested upgrade.
    func acceptUpgrade() {
        guard let next = suggestedNextStage else { return }
        transition(to: next)
        showUpgradePrompt = false
        suggestedNextStage = nil
        UserDefaults.standard.set(false, forKey: Self.declinedUpgradeKey)
        RNFLogger.engagement.info("Commitment stage upgraded to: \(next.rawValue)")
    }

    /// Decline the upgrade — won't be prompted again for this transition.
    func declineUpgrade() {
        showUpgradePrompt = false
        suggestedNextStage = nil
        UserDefaults.standard.set(true, forKey: Self.declinedUpgradeKey)
        RNFLogger.engagement.info("Commitment upgrade declined at stage: \(self.currentStage.rawValue)")
    }

    /// Manually set the stage (e.g., from settings).
    func setStage(_ stage: CommitmentStage) {
        transition(to: stage)
    }

    private func transition(to stage: CommitmentStage) {
        currentStage = stage
        let defaults = UserDefaults.standard
        defaults.set(stage.rawValue, forKey: Self.stageKey)
        // Reset declined flag for new stage
        defaults.set(false, forKey: Self.declinedUpgradeKey)
        defaults.set(0, forKey: Self.lastUpgradePromptKey)
    }

    // MARK: - Streak Behavior

    /// Whether a missed day should break the streak in current stage.
    func shouldBreakStreak(missedDays: Int) -> Bool {
        let config = currentConfiguration
        guard config.streakEnabled else { return false }

        if config.streakForgiving {
            // Foundation: forgive 1 miss
            return missedDays > 1
        }

        return missedDays > 0
    }

    /// Whether boss mechanics are active.
    var bossesActive: Bool {
        currentConfiguration.bossesEnabled
    }

    /// Whether streak is displayed (hidden in exploration).
    var streakVisible: Bool {
        currentConfiguration.streakEnabled
    }

    // MARK: - Auto-Upgrade (without prompt, if user prefers)

    /// Force-upgrades if past the stage duration. Used if user disables prompts.
    func autoUpgradeIfPastDuration() {
        let day = daysSinceStart
        switch currentStage {
        case .exploration:
            if day > Self.explorationDays * 2 {
                // 2x past exploration with no action — auto-upgrade
                transition(to: .foundation)
            }
        case .foundation:
            if day > Self.foundationDays * 2 {
                transition(to: .full)
            }
        case .full:
            break
        }
    }
}
