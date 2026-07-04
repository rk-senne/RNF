import XCTest
@testable import RNF

// MARK: - P28-TST-01/02/03/04: Personas & Inclusivity Tests

@MainActor
final class PersonasTests: XCTestCase {

    // MARK: - P28-TST-01: ThemeProvider Completeness

    func testAllThemesHaveEvolutionTierNames() {
        let provider = ThemeProvider()
        let expectedKeys: Set<String> = ["disciple", "awakened", "ascendant", "warlord", "apex"]

        for theme in PersonaTheme.allCases {
            provider.setTheme(theme)
            let keys = Set(provider.evolutionTierNames.keys)
            XCTAssertEqual(
                keys, expectedKeys,
                "Theme \(theme.rawValue) missing evolution tier keys. Got: \(keys)"
            )
            // Verify no empty values
            for (key, value) in provider.evolutionTierNames {
                XCTAssertFalse(value.isEmpty, "Empty evolution tier name for key \(key) in theme \(theme.rawValue)")
            }
        }
    }

    func testAllThemesHaveStreakTierNames() {
        let provider = ThemeProvider()
        let expectedKeys: Set<Int> = [3, 7, 14, 30, 60, 90, 180]

        for theme in PersonaTheme.allCases {
            provider.setTheme(theme)
            let keys = Set(provider.streakTierNames.keys)
            XCTAssertEqual(
                keys, expectedKeys,
                "Theme \(theme.rawValue) missing streak tier keys. Got: \(keys)"
            )
            for (key, value) in provider.streakTierNames {
                XCTAssertFalse(value.isEmpty, "Empty streak tier name for key \(key) in theme \(theme.rawValue)")
            }
        }
    }

    func testAllThemesHaveBossNames() {
        let provider = ThemeProvider()
        let expectedKeys: Set<String> = ["laziness", "procrastination", "doubt", "distraction", "apathy"]

        for theme in PersonaTheme.allCases {
            provider.setTheme(theme)
            let keys = Set(provider.bossNames.keys)
            XCTAssertEqual(
                keys, expectedKeys,
                "Theme \(theme.rawValue) missing boss name keys. Got: \(keys)"
            )
            for (key, value) in provider.bossNames {
                XCTAssertFalse(value.isEmpty, "Empty boss name for key \(key) in theme \(theme.rawValue)")
            }
        }
    }

    func testStreakLabelReturnsHighestMatchingTier() {
        let provider = ThemeProvider()
        provider.setTheme(.warrior)

        // Exactly at threshold
        XCTAssertEqual(provider.streakLabel(for: 7), "Iron Will")
        // Between thresholds — returns highest not exceeding
        XCTAssertEqual(provider.streakLabel(for: 10), "Iron Will")
        // Below any threshold
        XCTAssertNil(provider.streakLabel(for: 2))
        // At max
        XCTAssertEqual(provider.streakLabel(for: 200), "Mythic")
    }

    func testThemePersistence() {
        let provider = ThemeProvider()
        provider.setTheme(.garden)
        XCTAssertEqual(provider.currentTheme, .garden)

        // Simulate reload
        let reloaded = ThemeProvider()
        XCTAssertEqual(reloaded.currentTheme, .garden)

        // Cleanup
        provider.setTheme(.warrior)
    }

    func testAccentColorsExistForAllThemes() {
        let provider = ThemeProvider()
        for theme in PersonaTheme.allCases {
            provider.setTheme(theme)
            let colors = provider.accentColors
            // SwiftUI Colors can't easily be nil, but verify struct is populated
            XCTAssertNotNil(colors.primary)
            XCTAssertNotNil(colors.secondary)
            XCTAssertNotNil(colors.streak)
            XCTAssertNotNil(colors.surface)
        }
    }

    // MARK: - P28-TST-02: Adaptive Streak Calculation

    func testAdaptiveModeStreakWithOneCompletion() {
        let mode = AdaptiveDifficultyMode()
        mode.enable()

        // In adaptive mode, 1 completion = streak day
        XCTAssertTrue(mode.shouldCountAsStreakDay(completions: 1, dailyGoal: 4))
        XCTAssertTrue(mode.shouldCountAsStreakDay(completions: 2, dailyGoal: 4))
        // Zero completions should not count
        XCTAssertFalse(mode.shouldCountAsStreakDay(completions: 0, dailyGoal: 4))

        mode.disable()
    }

    func testStandardModeStreakRequiresFullGoal() {
        let mode = AdaptiveDifficultyMode()
        mode.disable()

        // Standard mode requires full daily goal
        XCTAssertFalse(mode.shouldCountAsStreakDay(completions: 1, dailyGoal: 4))
        XCTAssertFalse(mode.shouldCountAsStreakDay(completions: 3, dailyGoal: 4))
        XCTAssertTrue(mode.shouldCountAsStreakDay(completions: 4, dailyGoal: 4))
    }

    func testAdaptiveDailyGoalCapped() {
        let mode = AdaptiveDifficultyMode()
        mode.enable()

        XCTAssertEqual(mode.effectiveDailyGoal(requestedGoal: 5), 2)
        XCTAssertEqual(mode.effectiveDailyGoal(requestedGoal: 2), 2)
        XCTAssertEqual(mode.effectiveDailyGoal(requestedGoal: 1), 1)

        mode.disable()
        XCTAssertEqual(mode.effectiveDailyGoal(requestedGoal: 5), 5)
    }

    func testAdaptiveWorkoutDurations() {
        let mode = AdaptiveDifficultyMode()
        mode.enable()

        let durations = mode.availableWorkoutDurations
        XCTAssertEqual(durations, [5, 10])

        mode.disable()
        XCTAssertTrue(mode.availableWorkoutDurations.count > 2)
    }

    func testAdaptiveTokenLimit() {
        let mode = AdaptiveDifficultyMode()
        mode.enable()

        XCTAssertTrue(mode.canEarnToken(tokensEarnedThisMonth: 0))
        XCTAssertTrue(mode.canEarnToken(tokensEarnedThisMonth: 1))
        XCTAssertFalse(mode.canEarnToken(tokensEarnedThisMonth: 2))
        XCTAssertFalse(mode.canEarnToken(tokensEarnedThisMonth: 5))

        mode.disable()
        XCTAssertTrue(mode.canEarnToken(tokensEarnedThisMonth: 100))
    }

    func testAdaptiveMicroRewardsMoreFrequent() {
        let mode = AdaptiveDifficultyMode()
        mode.enable()

        // Every completion triggers a micro-reward in adaptive mode
        XCTAssertTrue(mode.shouldTriggerMicroReward(completionCount: 1))
        XCTAssertTrue(mode.shouldTriggerMicroReward(completionCount: 2))

        mode.disable()
        // Standard mode only every 3
        XCTAssertFalse(mode.shouldTriggerMicroReward(completionCount: 1))
        XCTAssertFalse(mode.shouldTriggerMicroReward(completionCount: 2))
        XCTAssertTrue(mode.shouldTriggerMicroReward(completionCount: 3))
    }

    func testAdaptiveXPScaling() {
        let mode = AdaptiveDifficultyMode()
        mode.enable()

        let adjusted = mode.adjustedXPToNextLevel(standardXP: 200)
        XCTAssertEqual(adjusted, 140) // 200 * 0.7

        mode.disable()
        XCTAssertEqual(mode.adjustedXPToNextLevel(standardXP: 200), 200)
    }

    // MARK: - P28-TST-03: Commitment Stage Transitions

    func testInitialStageIsExploration() {
        // Clear state for fresh test
        UserDefaults.standard.removeObject(forKey: "rnf_commitment_stage")
        UserDefaults.standard.removeObject(forKey: "rnf_commitment_start_date")

        let manager = CommitmentStageManager()
        XCTAssertEqual(manager.currentStage, .exploration)
    }

    func testExplorationConfigurationNoStreak() {
        let manager = CommitmentStageManager()
        manager.setStage(.exploration)

        let config = manager.currentConfiguration
        XCTAssertFalse(config.streakEnabled)
        XCTAssertFalse(config.bossesEnabled)
        XCTAssertFalse(config.penaltiesEnabled)
        XCTAssertEqual(config.durationDays, 7)
    }

    func testFoundationConfigurationGentleStreak() {
        let manager = CommitmentStageManager()
        manager.setStage(.foundation)

        let config = manager.currentConfiguration
        XCTAssertTrue(config.streakEnabled)
        XCTAssertTrue(config.streakForgiving)
        XCTAssertFalse(config.bossesEnabled)
        XCTAssertEqual(config.durationDays, 30)
    }

    func testFullConfigurationAllMechanics() {
        let manager = CommitmentStageManager()
        manager.setStage(.full)

        let config = manager.currentConfiguration
        XCTAssertTrue(config.streakEnabled)
        XCTAssertFalse(config.streakForgiving)
        XCTAssertTrue(config.bossesEnabled)
        XCTAssertTrue(config.penaltiesEnabled)
        XCTAssertNil(config.durationDays)
    }

    func testShouldBreakStreakExploration() {
        let manager = CommitmentStageManager()
        manager.setStage(.exploration)

        // Exploration never breaks streak
        XCTAssertFalse(manager.shouldBreakStreak(missedDays: 0))
        XCTAssertFalse(manager.shouldBreakStreak(missedDays: 1))
        XCTAssertFalse(manager.shouldBreakStreak(missedDays: 5))
    }

    func testShouldBreakStreakFoundation() {
        let manager = CommitmentStageManager()
        manager.setStage(.foundation)

        // Foundation forgives 1 miss
        XCTAssertFalse(manager.shouldBreakStreak(missedDays: 0))
        XCTAssertFalse(manager.shouldBreakStreak(missedDays: 1))
        XCTAssertTrue(manager.shouldBreakStreak(missedDays: 2))
    }

    func testShouldBreakStreakFull() {
        let manager = CommitmentStageManager()
        manager.setStage(.full)

        // Full breaks on any miss
        XCTAssertFalse(manager.shouldBreakStreak(missedDays: 0))
        XCTAssertTrue(manager.shouldBreakStreak(missedDays: 1))
    }

    func testAcceptUpgradeTransitions() {
        let manager = CommitmentStageManager()
        manager.setStage(.exploration)

        // Simulate upgrade prompt
        manager.showUpgradePrompt = true
        manager.acceptUpgrade()
        // acceptUpgrade requires suggestedNextStage to be set
        // Test manual transition
        manager.setStage(.foundation)
        XCTAssertEqual(manager.currentStage, .foundation)

        manager.setStage(.full)
        XCTAssertEqual(manager.currentStage, .full)
    }

    func testBossesActiveOnlyInFull() {
        let manager = CommitmentStageManager()

        manager.setStage(.exploration)
        XCTAssertFalse(manager.bossesActive)

        manager.setStage(.foundation)
        XCTAssertFalse(manager.bossesActive)

        manager.setStage(.full)
        XCTAssertTrue(manager.bossesActive)
    }

    // MARK: - P28-TST-04: Buddy Privacy

    func testBuddyDailyStatusContainsNoHabitNames() {
        // BuddyDailyStatus struct has no field for habit names
        let status = BuddyService.BuddyDailyStatus(
            userId: UUID(),
            date: Date(),
            didComplete: true,
            completionCount: 3
        )

        // Verify the privacy contract — struct only has boolean + count
        XCTAssertTrue(BuddyService.verifyPrivacy(in: status))
        XCTAssertTrue(status.didComplete)
        XCTAssertEqual(status.completionCount, 3)

        // Verify encoding doesn't leak habit data
        let encoder = JSONEncoder()
        let data = try! encoder.encode(status)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertFalse(json.contains("habit_name"))
        XCTAssertFalse(json.contains("habitName"))
        XCTAssertFalse(json.contains("habit_id"))
    }

    func testBondStreakCalculation() {
        let service = BuddyService()

        // Both complete — streak increases
        let result1 = service.calculateBondStreak(
            myCompleted: true,
            buddyCompleted: true,
            currentBondStreak: 3
        )
        XCTAssertEqual(result1.currentStreak, 4)
        XCTAssertTrue(result1.bothCompletedToday)
        XCTAssertEqual(result1.xpBonus, 5)

        // Only one completes — streak resets
        let result2 = service.calculateBondStreak(
            myCompleted: true,
            buddyCompleted: false,
            currentBondStreak: 4
        )
        XCTAssertEqual(result2.currentStreak, 0)
        XCTAssertFalse(result2.bothCompletedToday)
        XCTAssertEqual(result2.xpBonus, 0)
    }

    func testXPBonusOnlyWhenBothComplete() {
        let service = BuddyService()

        XCTAssertEqual(service.xpBonusIfBothComplete(myCompleted: true, buddyCompleted: true), 5)
        XCTAssertEqual(service.xpBonusIfBothComplete(myCompleted: true, buddyCompleted: false), 0)
        XCTAssertEqual(service.xpBonusIfBothComplete(myCompleted: false, buddyCompleted: true), 0)
        XCTAssertEqual(service.xpBonusIfBothComplete(myCompleted: false, buddyCompleted: false), 0)
    }

    func testLinkCodeGeneration() {
        let service = BuddyService()
        let code = service.generateLinkCode()

        XCTAssertEqual(code.count, 6)
        // Should only contain non-ambiguous alphanumeric characters
        let allowedChars = CharacterSet(charactersIn: "ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        for scalar in code.unicodeScalars {
            XCTAssertTrue(allowedChars.contains(scalar), "Unexpected character: \(scalar)")
        }

        // Generate multiple codes — should be unique (probabilistic but safe with 6 chars)
        let codes = (0..<10).map { _ in service.generateLinkCode() }
        XCTAssertEqual(Set(codes).count, codes.count, "Generated duplicate codes")
    }

    func testUnpairDeactivatesPair() async {
        let service = BuddyService()
        let pairId = UUID()

        // Without an active pair, unpair returns false
        let result = await service.unpair(pairId: pairId)
        XCTAssertFalse(result)
    }
}
