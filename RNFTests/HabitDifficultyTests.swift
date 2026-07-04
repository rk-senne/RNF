import XCTest
@testable import RNF

/// P25-TST-05: Tests for HabitDifficultyProfiler — classification boundaries and XP bonus.
final class HabitDifficultyTests: XCTestCase {

    private let difficultyDataKey = "rnf_habit_difficulty_ratings"

    override func setUp() {
        super.setUp()
        clearDefaults()
    }

    override func tearDown() {
        clearDefaults()
        super.tearDown()
    }

    private func clearDefaults() {
        UserDefaults.standard.removeObject(forKey: difficultyDataKey)
    }

    // MARK: - Classification Boundaries

    func testRateAbove90PercentClassifiesAsEasy() {
        let difficulty = HabitDifficultyProfiler.classify(completionRate: 0.91)
        XCTAssertEqual(difficulty, .easy)
    }

    func testRateExactly90PercentClassifiesAsEasy() {
        // >90% boundary: 90% itself is the boundary for moderate
        // Per spec: > 90% = Easy, so exactly 90% is NOT Easy
        let difficulty = HabitDifficultyProfiler.classify(completionRate: 0.90)
        XCTAssertEqual(difficulty, .moderate,
                       "Exactly 90% should be Moderate (Easy requires >90%)")
    }

    func testRate91PercentClassifiesAsEasy() {
        let difficulty = HabitDifficultyProfiler.classify(completionRate: 0.91)
        XCTAssertEqual(difficulty, .easy)
    }

    func testRate100PercentClassifiesAsEasy() {
        let difficulty = HabitDifficultyProfiler.classify(completionRate: 1.0)
        XCTAssertEqual(difficulty, .easy)
    }

    func testRate89PercentClassifiesAsModerate() {
        let difficulty = HabitDifficultyProfiler.classify(completionRate: 0.89)
        XCTAssertEqual(difficulty, .moderate)
    }

    func testRate60PercentClassifiesAsModerate() {
        // Per spec: 60% - 90% = Moderate (inclusive at 60%)
        let difficulty = HabitDifficultyProfiler.classify(completionRate: 0.60)
        XCTAssertEqual(difficulty, .moderate,
                       "Exactly 60% should be Moderate (Hard requires <60%)")
    }

    func testRate75PercentClassifiesAsModerate() {
        let difficulty = HabitDifficultyProfiler.classify(completionRate: 0.75)
        XCTAssertEqual(difficulty, .moderate)
    }

    func testRate59PercentClassifiesAsHard() {
        let difficulty = HabitDifficultyProfiler.classify(completionRate: 0.59)
        XCTAssertEqual(difficulty, .hard)
    }

    func testRate50PercentClassifiesAsHard() {
        let difficulty = HabitDifficultyProfiler.classify(completionRate: 0.50)
        XCTAssertEqual(difficulty, .hard)
    }

    func testRate0PercentClassifiesAsHard() {
        let difficulty = HabitDifficultyProfiler.classify(completionRate: 0.0)
        XCTAssertEqual(difficulty, .hard)
    }

    func testRate10PercentClassifiesAsHard() {
        let difficulty = HabitDifficultyProfiler.classify(completionRate: 0.10)
        XCTAssertEqual(difficulty, .hard)
    }

    // MARK: - XP Bonus for Difficulty

    func testEasyHabitGivesZeroBonusXP() {
        let bonus = HabitDifficulty.easy.bonusXP
        XCTAssertEqual(bonus, 0)
    }

    func testModerateHabitGives1BonusXP() {
        let bonus = HabitDifficulty.moderate.bonusXP
        XCTAssertEqual(bonus, 1)
    }

    func testHardHabitGives3BonusXP() {
        let bonus = HabitDifficulty.hard.bonusXP
        XCTAssertEqual(bonus, 3)
    }

    // MARK: - XP Calculation with Difficulty

    func testTotalXPIncludesBaseAndBonus() {
        let baseXP = 10
        let difficulty = HabitDifficulty.hard

        let totalXP = baseXP + difficulty.bonusXP

        XCTAssertEqual(totalXP, 13, "10 base + 3 hard bonus = 13")
    }

    func testEasyHabitTotalXPIsJustBase() {
        let baseXP = 10
        let difficulty = HabitDifficulty.easy

        let totalXP = baseXP + difficulty.bonusXP

        XCTAssertEqual(totalXP, 10, "10 base + 0 easy bonus = 10")
    }

    // MARK: - Minimum Data Requirement

    func testRequiresMinimum7DaysBeforeClassification() {
        let canClassify = HabitDifficultyProfiler.hasEnoughData(daysSinceCreation: 7)
        XCTAssertTrue(canClassify)
    }

    func testCannotClassifyBefore7Days() {
        let canClassify = HabitDifficultyProfiler.hasEnoughData(daysSinceCreation: 6)
        XCTAssertFalse(canClassify, "Should not classify before 7 days of data")
    }

    func testNewHabitsDefaultToModerate() {
        let defaultDifficulty = HabitDifficultyProfiler.defaultDifficulty
        XCTAssertEqual(defaultDifficulty, .moderate,
                       "New habits should default to Moderate until classified")
    }

    // MARK: - Stability Rule (No Reclassification for Same Tier)

    func testNoReclassificationWithinSameTier() {
        // Currently Easy (92%), new rate still Easy (95%)
        let shouldReclassify = HabitDifficultyProfiler.shouldReclassify(
            currentDifficulty: .easy,
            newRate: 0.95
        )

        XCTAssertFalse(shouldReclassify, "Should not reclassify if tier hasn't changed")
    }

    func testReclassifiesWhenTierChanges() {
        // Currently Easy (was 92%), new rate 85% → Moderate
        let shouldReclassify = HabitDifficultyProfiler.shouldReclassify(
            currentDifficulty: .easy,
            newRate: 0.85
        )

        XCTAssertTrue(shouldReclassify, "Should reclassify when tier changes")
    }

    func testReclassifiesFromModerateToHard() {
        let shouldReclassify = HabitDifficultyProfiler.shouldReclassify(
            currentDifficulty: .moderate,
            newRate: 0.45
        )

        XCTAssertTrue(shouldReclassify)
    }

    func testReclassifiesFromHardToModerate() {
        let shouldReclassify = HabitDifficultyProfiler.shouldReclassify(
            currentDifficulty: .hard,
            newRate: 0.70
        )

        XCTAssertTrue(shouldReclassify)
    }

    func testNoReclassificationWithinModerate() {
        // Currently Moderate (75%), new rate still Moderate (65%)
        let shouldReclassify = HabitDifficultyProfiler.shouldReclassify(
            currentDifficulty: .moderate,
            newRate: 0.65
        )

        XCTAssertFalse(shouldReclassify)
    }

    // MARK: - Batch Classification

    func testClassifiesMultipleHabits() {
        let habitRates: [(UUID, Double)] = [
            (UUID(), 0.95),  // Easy
            (UUID(), 0.75),  // Moderate
            (UUID(), 0.40)   // Hard
        ]

        let classifications = HabitDifficultyProfiler.classifyBatch(habitRates)

        XCTAssertEqual(classifications.count, 3)
        XCTAssertEqual(classifications[0].difficulty, .easy)
        XCTAssertEqual(classifications[1].difficulty, .moderate)
        XCTAssertEqual(classifications[2].difficulty, .hard)
    }

    // MARK: - Edge Cases

    func testCompletionRateClampedTo0Through1() {
        // Even if somehow rate exceeds 1.0, should still classify as easy
        let difficulty = HabitDifficultyProfiler.classify(completionRate: 1.5)
        XCTAssertEqual(difficulty, .easy)
    }

    func testNegativeRateClassifiesAsHard() {
        // Guard against negative rates (defensive)
        let difficulty = HabitDifficultyProfiler.classify(completionRate: -0.1)
        XCTAssertEqual(difficulty, .hard)
    }
}
