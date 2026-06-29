import XCTest
@testable import RNF

final class StreakTierSystemTests: XCTestCase {

    // MARK: - Tier Assignment

    func testSparkTierForDays0Through6() {
        XCTAssertEqual(StreakTierSystem.tier(for: 0), .spark)
        XCTAssertEqual(StreakTierSystem.tier(for: 6), .spark)
    }

    func testEmberTierForDays7Through13() {
        XCTAssertEqual(StreakTierSystem.tier(for: 7), .ember)
        XCTAssertEqual(StreakTierSystem.tier(for: 13), .ember)
    }

    func testFlameTierForDays14Through29() {
        XCTAssertEqual(StreakTierSystem.tier(for: 14), .flame)
        XCTAssertEqual(StreakTierSystem.tier(for: 29), .flame)
    }

    func testBlazeTierForDays30Through59() {
        XCTAssertEqual(StreakTierSystem.tier(for: 30), .blaze)
        XCTAssertEqual(StreakTierSystem.tier(for: 59), .blaze)
    }

    func testInfernoTierForDays60Through89() {
        XCTAssertEqual(StreakTierSystem.tier(for: 60), .inferno)
        XCTAssertEqual(StreakTierSystem.tier(for: 89), .inferno)
    }

    func testEternalTierForDays90Plus() {
        XCTAssertEqual(StreakTierSystem.tier(for: 90), .eternal)
        XCTAssertEqual(StreakTierSystem.tier(for: 365), .eternal)
    }

    // MARK: - Multiplier Values

    func testMultiplierMatchesTier() {
        XCTAssertEqual(StreakTierSystem.multiplier(for: 0), 1.0)
        XCTAssertEqual(StreakTierSystem.multiplier(for: 7), 1.05)
        XCTAssertEqual(StreakTierSystem.multiplier(for: 14), 1.10)
        XCTAssertEqual(StreakTierSystem.multiplier(for: 30), 1.15)
        XCTAssertEqual(StreakTierSystem.multiplier(for: 60), 1.20)
        XCTAssertEqual(StreakTierSystem.multiplier(for: 90), 1.25)
    }

    // MARK: - Streak Multiplier Stacks With Perk XP

    func testModifiedXPRewardAppliesStreakMultiplier() {
        let perks = ActivePerkSummary.empty
        let result = PerkSystem.modifiedXPReward(
            baseXP: 10,
            activePerks: perks,
            streak: 90
        )
        // 10 * 1.25 = 12
        XCTAssertEqual(result, 12)
    }

    func testStreakMultiplierStacksOnPerkMultiplier() {
        let perks = ActivePerkSummary(
            effects: [],
            unlockedSkillNodeIDs: [],
            xpMultiplierPercent: 20,
            statBonuses: [:],
            questRewardBonus: 0,
            streakProtectionCount: 0
        )
        let result = PerkSystem.modifiedXPReward(
            baseXP: 10,
            activePerks: perks,
            streak: 90
        )
        // base 10 + 20% perk = 12, then * 1.25 streak = 15
        XCTAssertEqual(result, 15)
    }

    func testZeroStreakGivesNoBonus() {
        let perks = ActivePerkSummary.empty
        let result = PerkSystem.modifiedXPReward(
            baseXP: 10,
            activePerks: perks,
            streak: 0
        )
        XCTAssertEqual(result, 10)
    }
}
