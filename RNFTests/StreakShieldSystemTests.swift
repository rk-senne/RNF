import XCTest
@testable import RNF

@MainActor
final class StreakShieldSystemTests: XCTestCase {
    
    // MARK: - canEquipShield
    
    func testCanEquipShield_underCapWithTokens_returnsTrue() {
        XCTAssertTrue(StreakShieldSystem.canEquipShield(equippedShields: 0, forgeTokenBalance: 3))
        XCTAssertTrue(StreakShieldSystem.canEquipShield(equippedShields: 1, forgeTokenBalance: 5))
    }
    
    func testCanEquipShield_atCap_returnsFalse() {
        XCTAssertFalse(StreakShieldSystem.canEquipShield(equippedShields: 2, forgeTokenBalance: 10))
    }
    
    func testCanEquipShield_insufficientTokens_returnsFalse() {
        XCTAssertFalse(StreakShieldSystem.canEquipShield(equippedShields: 0, forgeTokenBalance: 2))
        XCTAssertFalse(StreakShieldSystem.canEquipShield(equippedShields: 0, forgeTokenBalance: 0))
    }
    
    // MARK: - equipShield
    
    func testEquipShield_incrementsCount() {
        XCTAssertEqual(StreakShieldSystem.equipShield(currentShields: 0), 1)
        XCTAssertEqual(StreakShieldSystem.equipShield(currentShields: 1), 2)
    }
    
    func testEquipShield_capsAtMax() {
        XCTAssertEqual(StreakShieldSystem.equipShield(currentShields: 2), 2)
    }
    
    // MARK: - evaluateMissedDay
    
    func testEvaluateMissedDay_withShields_protects() {
        let result = StreakShieldSystem.evaluateMissedDay(equippedShields: 2)
        XCTAssertTrue(result.shouldProtect)
        XCTAssertEqual(result.remainingShields, 1)
    }
    
    func testEvaluateMissedDay_noShields_noProtection() {
        let result = StreakShieldSystem.evaluateMissedDay(equippedShields: 0)
        XCTAssertFalse(result.shouldProtect)
        XCTAssertEqual(result.remainingShields, 0)
    }
    
    // MARK: - updateStreakWithShield
    
    func testUpdateStreak_completedDay_incrementsStreak() {
        let result = StreakShieldSystem.updateStreakWithShield(
            currentStreak: 5,
            dailyCompleted: 4,
            dailyGoal: 4,
            dayMissed: false,
            equippedShields: 1
        )
        XCTAssertEqual(result.newStreak, 6)
        XCTAssertEqual(result.shieldsRemaining, 1)
        XCTAssertFalse(result.shieldUsed)
    }
    
    func testUpdateStreak_missedWithShield_preservesStreak() {
        let result = StreakShieldSystem.updateStreakWithShield(
            currentStreak: 10,
            dailyCompleted: 0,
            dailyGoal: 4,
            dayMissed: true,
            equippedShields: 1
        )
        XCTAssertEqual(result.newStreak, 10)
        XCTAssertEqual(result.shieldsRemaining, 0)
        XCTAssertTrue(result.shieldUsed)
    }
    
    func testUpdateStreak_missedWithoutShield_resetsStreak() {
        let result = StreakShieldSystem.updateStreakWithShield(
            currentStreak: 10,
            dailyCompleted: 0,
            dailyGoal: 4,
            dayMissed: true,
            equippedShields: 0
        )
        XCTAssertEqual(result.newStreak, 0)
        XCTAssertEqual(result.shieldsRemaining, 0)
        XCTAssertFalse(result.shieldUsed)
    }
    
    func testUpdateStreak_partialWithShield_preservesStreak() {
        let result = StreakShieldSystem.updateStreakWithShield(
            currentStreak: 7,
            dailyCompleted: 2,
            dailyGoal: 4,
            dayMissed: false,
            equippedShields: 2
        )
        XCTAssertEqual(result.newStreak, 7)
        XCTAssertEqual(result.shieldsRemaining, 1)
        XCTAssertTrue(result.shieldUsed)
    }
    
    // MARK: - Cost constant
    
    func testShieldCostIsThreeTokens() {
        XCTAssertEqual(StreakShieldSystem.shieldCost, 3)
    }
    
    func testMaxEquippedIsTwo() {
        XCTAssertEqual(StreakShieldSystem.maxEquipped, 2)
    }
}
