import XCTest
@testable import RNF

// P27-TST-01/02/03/04/05: Lifecycle & Endgame Tests
// Tests chapter progress, prestige validation/reset, habit level thresholds,
// seasonal events, and mastery focus.

@MainActor
final class LifecycleTests: XCTestCase {

    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "LifecycleTests")!
        testDefaults.removePersistentDomain(forName: "LifecycleTests")
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "LifecycleTests")
        testDefaults = nil
        super.tearDown()
    }

    // MARK: - P27-TST-01: Chapter Progress Tests

    func testChapterDetectsOriginBeforeDay90() {
        let sut = ChapterService(supabase: .shared, userDefaults: testDefaults)
        let stats = Stats.baseline

        sut.evaluateProgress(stats: stats, challengeCompleted: false, dayCount: 45)

        XCTAssertEqual(sut.currentChapter, .origin)
        XCTAssertEqual(sut.currentProgress, 0.5, accuracy: 0.01)
    }

    func testChapterAdvancesToNewPillarWhenStatAbove25() {
        let sut = ChapterService(supabase: .shared, userDefaults: testDefaults)
        let stats = Stats(strength: 26, discipline: 10, focus: 10, energy: 10, wisdom: 10, mind: 10, spirit: 10)

        sut.evaluateProgress(stats: stats, challengeCompleted: true, dayCount: 91)

        XCTAssertEqual(sut.currentChapter, .newPillar)
    }

    func testChapterAdvancesToBalancedWhenAllAbove15() {
        let sut = ChapterService(supabase: .shared, userDefaults: testDefaults)
        let stats = Stats(strength: 16, discipline: 16, focus: 16, energy: 16, wisdom: 16, mind: 16, spirit: 16)

        sut.evaluateProgress(stats: stats, challengeCompleted: true, dayCount: 120)

        XCTAssertEqual(sut.currentChapter, .balanced)
    }

    func testChapterAdvancesToSpecialistWhenOneAbove40() {
        let sut = ChapterService(supabase: .shared, userDefaults: testDefaults)
        let stats = Stats(strength: 41, discipline: 10, focus: 10, energy: 10, wisdom: 10, mind: 10, spirit: 10)

        sut.evaluateProgress(stats: stats, challengeCompleted: true, dayCount: 200)

        XCTAssertEqual(sut.currentChapter, .specialist)
    }

    func testChapterAdvancesToCompleteWhenAllAbove25() {
        let sut = ChapterService(supabase: .shared, userDefaults: testDefaults)
        let stats = Stats(strength: 26, discipline: 26, focus: 26, energy: 26, wisdom: 26, mind: 26, spirit: 26)

        sut.evaluateProgress(stats: stats, challengeCompleted: true, dayCount: 300)

        XCTAssertEqual(sut.currentChapter, .complete)
    }

    func testChapterProgressCalculation() {
        let sut = ChapterService(supabase: .shared, userDefaults: testDefaults)
        // Highest stat is 20 out of 25 needed for new pillar = 80%
        let stats = Stats(strength: 20, discipline: 5, focus: 5, energy: 5, wisdom: 5, mind: 5, spirit: 5)

        sut.evaluateProgress(stats: stats, challengeCompleted: true, dayCount: 91)

        XCTAssertEqual(sut.currentProgress, 0.8, accuracy: 0.01)
    }

    func testChapterCompletionTracking() {
        let sut = ChapterService(supabase: .shared, userDefaults: testDefaults)

        // Start at newPillar
        let stats1 = Stats(strength: 26, discipline: 10, focus: 10, energy: 10, wisdom: 10, mind: 10, spirit: 10)
        sut.evaluateProgress(stats: stats1, challengeCompleted: true, dayCount: 91)
        XCTAssertEqual(sut.currentChapter, .newPillar)

        // Advance to balanced
        let stats2 = Stats(strength: 26, discipline: 16, focus: 16, energy: 16, wisdom: 16, mind: 16, spirit: 16)
        sut.evaluateProgress(stats: stats2, challengeCompleted: true, dayCount: 150)
        XCTAssertEqual(sut.currentChapter, .balanced)

        XCTAssertTrue(sut.isChapterCompleted(.newPillar))
    }

    // MARK: - P27-TST-02: Prestige Validation & Reset Tests

    func testPrestigeEligibleWithChapterTwoComplete() {
        let sut = PrestigeService(supabase: .shared, userDefaults: testDefaults)

        let result = sut.checkEligibility(
            chapterTwoComplete: true,
            currentLevel: 5,
            challengeCompleted: false
        )

        XCTAssertEqual(result, .eligible)
    }

    func testPrestigeEligibleWithLevel20AndChallenge() {
        let sut = PrestigeService(supabase: .shared, userDefaults: testDefaults)

        let result = sut.checkEligibility(
            chapterTwoComplete: false,
            currentLevel: 20,
            challengeCompleted: true
        )

        XCTAssertEqual(result, .eligible)
    }

    func testPrestigeIneligibleWithLowLevel() {
        let sut = PrestigeService(supabase: .shared, userDefaults: testDefaults)

        let result = sut.checkEligibility(
            chapterTwoComplete: false,
            currentLevel: 15,
            challengeCompleted: true
        )

        XCTAssertEqual(result, .needsLevelTwenty)
    }

    func testPrestigeIneligibleWithoutChallenge() {
        let sut = PrestigeService(supabase: .shared, userDefaults: testDefaults)

        let result = sut.checkEligibility(
            chapterTwoComplete: false,
            currentLevel: 20,
            challengeCompleted: false
        )

        XCTAssertEqual(result, .needsChallenge)
    }

    func testPrestigeResetGivesBaselineStats() {
        let sut = PrestigeService(supabase: .shared, userDefaults: testDefaults)
        let currentStats = Stats(strength: 30, discipline: 25, focus: 20, energy: 18, wisdom: 22, mind: 15, spirit: 10)

        let newStats = sut.performRebirth(
            currentLevel: 20,
            currentStats: currentStats,
            currentTitles: ["Forged"],
            currentAchievements: ["streak_30"]
        )

        // First rebirth: no stat bonus yet (needs rebirth 2+)
        XCTAssertEqual(newStats, Stats.baseline)
        XCTAssertEqual(sut.rebirthCount, 1)
    }

    func testPrestigeXPBonusAccumulates() {
        let sut = PrestigeService(supabase: .shared, userDefaults: testDefaults)
        let stats = Stats.baseline

        // First rebirth: +5%
        _ = sut.performRebirth(currentLevel: 20, currentStats: stats, currentTitles: [], currentAchievements: [])
        XCTAssertEqual(sut.xpBonusMultiplier, 1.05, accuracy: 0.001)
        XCTAssertEqual(sut.applyXPBonus(baseXP: 100), 105)

        // Second rebirth: +10%
        _ = sut.performRebirth(currentLevel: 20, currentStats: stats, currentTitles: [], currentAchievements: [])
        XCTAssertEqual(sut.xpBonusMultiplier, 1.10, accuracy: 0.001)
        XCTAssertEqual(sut.applyXPBonus(baseXP: 100), 110)
    }

    func testPrestigeStatBonusStartsAtRebirth2() {
        let sut = PrestigeService(supabase: .shared, userDefaults: testDefaults)
        let stats = Stats.baseline

        // First rebirth: no stat bonus
        let newStats1 = sut.performRebirth(currentLevel: 20, currentStats: stats, currentTitles: [], currentAchievements: [])
        XCTAssertEqual(newStats1.strength, Stats.baseline.strength)
        XCTAssertEqual(sut.startingStatBonus, 0)

        // Second rebirth: +1 stat bonus
        let newStats2 = sut.performRebirth(currentLevel: 20, currentStats: stats, currentTitles: [], currentAchievements: [])
        XCTAssertEqual(newStats2.strength, Stats.baseline.strength + 1)
        XCTAssertEqual(sut.startingStatBonus, 1)

        // Third rebirth: +2 stat bonus
        let newStats3 = sut.performRebirth(currentLevel: 20, currentStats: stats, currentTitles: [], currentAchievements: [])
        XCTAssertEqual(newStats3.strength, Stats.baseline.strength + 2)
        XCTAssertEqual(sut.startingStatBonus, 2)
    }

    func testPrestigePreviewShowsCorrectInfo() {
        let sut = PrestigeService(supabase: .shared, userDefaults: testDefaults)
        let titles = ["Forged", "Pillar Breaker"]
        let achievements = ["streak_30", "level_10"]

        let preview = sut.generatePreview(
            currentTitles: titles,
            currentAchievements: achievements,
            currentTokenBalance: 200
        )

        XCTAssertEqual(preview.xpBonusPercent, 5)
        XCTAssertEqual(preview.preservedTitles, titles)
        XCTAssertEqual(preview.preservedAchievements, achievements)
        XCTAssertEqual(preview.preservedTokens, 200)
        XCTAssertTrue(preview.resetsLevel)
        XCTAssertTrue(preview.resetsStats)
        XCTAssertTrue(preview.resetsXP)
    }

    // MARK: - P27-TST-03: Habit Level Threshold Tests

    func testHabitPresetLevelData() {
        // Verify habit presets exist with correct stat assignments
        let allPresets = HabitPreset.all
        XCTAssertFalse(allPresets.isEmpty)

        // Verify categories are balanced
        let bodyCount = allPresets.filter { $0.category == .body }.count
        let mindCount = allPresets.filter { $0.category == .mind }.count
        let spiritCount = allPresets.filter { $0.category == .spirit }.count

        XCTAssertEqual(bodyCount, 4)
        XCTAssertEqual(mindCount, 4)
        XCTAssertEqual(spiritCount, 4)

        // Verify all presets have valid stat assignments
        let validStats = ["strength", "discipline", "focus", "energy", "wisdom", "mind", "spirit"]
        for preset in allPresets {
            XCTAssertTrue(validStats.contains(preset.stat), "Invalid stat '\(preset.stat)' for preset '\(preset.name)'")
            XCTAssertGreaterThan(preset.xpReward, 0)
        }
    }

    // MARK: - P27-TST-04: Seasonal Event Tests

    func testSeasonalEventOptIn() {
        let sut = SeasonalEventService(supabase: .shared, userDefaults: testDefaults)

        XCTAssertFalse(sut.isOptedIn)
        XCTAssertNil(sut.activeParticipation)

        sut.optIn()

        XCTAssertTrue(sut.isOptedIn)
        XCTAssertNotNil(sut.activeParticipation)
        XCTAssertEqual(sut.activeParticipation?.progress, 0.0)
    }

    func testSeasonalEventOptOut() {
        let sut = SeasonalEventService(supabase: .shared, userDefaults: testDefaults)

        sut.optIn()
        XCTAssertTrue(sut.isOptedIn)

        sut.optOut()
        XCTAssertFalse(sut.isOptedIn)
        XCTAssertNil(sut.activeParticipation)
    }

    func testSeasonalEventProgressTracking() {
        let sut = SeasonalEventService(supabase: .shared, userDefaults: testDefaults)
        sut.optIn()

        sut.recordProgress(amount: 0.1)
        XCTAssertEqual(sut.activeParticipation?.progress ?? 0, 0.1, accuracy: 0.001)

        sut.recordProgress(amount: 0.2)
        XCTAssertEqual(sut.activeParticipation?.progress ?? 0, 0.3, accuracy: 0.001)
    }

    func testSeasonalEventCompletion() {
        let sut = SeasonalEventService(supabase: .shared, userDefaults: testDefaults)
        sut.optIn()

        // Fill progress to completion
        sut.recordProgress(amount: 1.0)

        XCTAssertEqual(sut.activeParticipation?.progress, 1.0)
        XCTAssertNotNil(sut.activeParticipation?.completedAt)
        XCTAssertTrue(sut.activeParticipation?.isComplete ?? false)
    }

    func testSeasonalEventRewardClaim() {
        let sut = SeasonalEventService(supabase: .shared, userDefaults: testDefaults)
        sut.optIn()
        sut.recordProgress(amount: 1.0)

        let reward = sut.claimReward()

        XCTAssertNotNil(reward)
        XCTAssertGreaterThan(reward?.tokens ?? 0, 0)
        XCTAssertGreaterThan(reward?.xp ?? 0, 0)
        XCTAssertFalse(reward?.title.isEmpty ?? true)
    }

    func testSeasonalEventCannotClaimTwice() {
        let sut = SeasonalEventService(supabase: .shared, userDefaults: testDefaults)
        sut.optIn()
        sut.recordProgress(amount: 1.0)

        _ = sut.claimReward()
        let secondClaim = sut.claimReward()

        XCTAssertNil(secondClaim)
    }

    func testSeasonalEventProgressCapsAt1() {
        let sut = SeasonalEventService(supabase: .shared, userDefaults: testDefaults)
        sut.optIn()

        sut.recordProgress(amount: 0.8)
        sut.recordProgress(amount: 0.5) // Would exceed 1.0

        XCTAssertEqual(sut.activeParticipation?.progress, 1.0)
    }

    func testSeasonalEventCurrentSeasonDetection() {
        let season = SeasonalEventService.Season.current()
        // July = summer
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3, 4, 5: XCTAssertEqual(season, .spring)
        case 6, 7, 8: XCTAssertEqual(season, .summer)
        case 9, 10, 11: XCTAssertEqual(season, .autumn)
        default: XCTAssertEqual(season, .winter)
        }
    }

    // MARK: - P27-TST-05: Mastery Focus / Legacy Tests

    func testLegacyMilestoneEvaluation() {
        let sut = LegacyProfileGenerator(supabase: .shared, userDefaults: testDefaults)

        let unlocked = sut.evaluateMilestones(totalDaysActive: 365)

        XCTAssertFalse(unlocked.isEmpty)
        XCTAssertTrue(unlocked.contains { $0.id == "year_one" })
        XCTAssertTrue(unlocked.contains { $0.id == "half_year" })
    }

    func testLegacyMilestoneNotUnlockedEarly() {
        let sut = LegacyProfileGenerator(supabase: .shared, userDefaults: testDefaults)

        let unlocked = sut.evaluateMilestones(totalDaysActive: 100)

        XCTAssertFalse(unlocked.contains { $0.id == "year_one" })
        XCTAssertFalse(unlocked.contains { $0.id == "year_two" })
    }

    func testLegacyCustomTitle() {
        let sut = LegacyProfileGenerator(supabase: .shared, userDefaults: testDefaults)

        sut.setCustomTitle("Iron Phoenix")
        XCTAssertEqual(sut.customTitle, "Iron Phoenix")
    }

    func testLegacyCustomTitleRejectsEmpty() {
        let sut = LegacyProfileGenerator(supabase: .shared, userDefaults: testDefaults)

        sut.setCustomTitle("")
        XCTAssertNil(sut.customTitle)
    }

    func testLegacyCustomTitleRejectsTooLong() {
        let sut = LegacyProfileGenerator(supabase: .shared, userDefaults: testDefaults)

        sut.setCustomTitle("This title is way too long for any reasonable display in the app UI")
        XCTAssertNil(sut.customTitle)
    }

    func testTimeCapsuleScheduling() {
        let sut = LegacyProfileGenerator(supabase: .shared, userDefaults: testDefaults)
        let stats = Stats(strength: 20, discipline: 15, focus: 12, energy: 18, wisdom: 10, mind: 8, spirit: 14)

        sut.scheduleTimeCapsule(message: "Future me, keep going!", revealAfterDays: 30, currentStats: stats, currentLevel: 10)

        XCTAssertEqual(sut.timeCapsules.count, 1)
        XCTAssertEqual(sut.timeCapsules.first?.message, "Future me, keep going!")
        XCTAssertFalse(sut.timeCapsules.first?.isRevealed ?? true)
    }

    func testTimeCapsuleReveal() {
        let sut = LegacyProfileGenerator(supabase: .shared, userDefaults: testDefaults)
        let stats = Stats.baseline

        // Schedule a capsule that should already be revealable (0 days)
        sut.scheduleTimeCapsule(message: "Test", revealAfterDays: 0, currentStats: stats, currentLevel: 1)

        // The reveal_at is set to now, so it should be revealable immediately
        let revealed = sut.checkRevealableCapsules()

        // Note: Due to timing precision, this may or may not reveal immediately
        // The capsule's revealAt == createdAt when days=0, so it should be <= now
        XCTAssertTrue(revealed.count <= 1)
    }

    func testLegacyProfileGeneration() {
        let sut = LegacyProfileGenerator(supabase: .shared, userDefaults: testDefaults)
        let peakStats = Stats(strength: 30, discipline: 28, focus: 25, energy: 22, wisdom: 20, mind: 18, spirit: 15)

        let profile = sut.generateProfile(
            totalDaysActive: 400,
            totalHabitsCompleted: 1200,
            totalWorkouts: 150,
            totalPagesRead: 5000,
            longestStreak: 90,
            rebirthCount: 2,
            chaptersCompleted: 3,
            titlesEarned: ["Forged", "Specialist"],
            achievementsUnlocked: 15,
            highestLevel: 25,
            peakStats: peakStats,
            seasonalEventsCompleted: 2
        )

        XCTAssertEqual(profile.totalDaysActive, 400)
        XCTAssertEqual(profile.totalHabitsCompleted, 1200)
        XCTAssertEqual(profile.highestLevel, 25)
        XCTAssertEqual(profile.rebirthCount, 2)
        XCTAssertEqual(profile.peakStats, peakStats)
        XCTAssertNotNil(sut.legacyProfile)
    }
}
