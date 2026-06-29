import XCTest
@testable import RNF

final class BossSystemTests: XCTestCase {

    func testBossHPScalesWithLevel() {
        XCTAssertEqual(BossSystem.bossHP(for: 1), 15)
        XCTAssertEqual(BossSystem.bossHP(for: 10), 60)
        XCTAssertEqual(BossSystem.bossHP(for: 20), 110)
    }

    func testDefeatRewardScalesWithLevel() {
        XCTAssertEqual(BossSystem.defeatReward(bossLevel: 10), 150)
        XCTAssertEqual(BossSystem.defeatReward(bossLevel: 20), 250)
    }

    func testSelectBossTypeTargetsWeakestStat() {
        let stats = Stats(strength: 5, discipline: 1, focus: 3, energy: 4, wisdom: 2, mind: 3, spirit: 6)
        let type = BossSystem.selectBossType(for: stats)
        XCTAssertEqual(type, .procrastination) // discipline is lowest
    }

    func testBossCreationUsesCorrectHP() {
        let boss = Boss.create(type: .doubt, level: 10)
        XCTAssertEqual(boss.maxHP, 60)
        XCTAssertEqual(boss.currentHP, 60)
        XCTAssertEqual(boss.status, .active)
        XCTAssertFalse(boss.isDefeated)
    }

    func testDamageConstants() {
        XCTAssertEqual(BossSystem.damagePerHabit, 1)
        XCTAssertEqual(BossSystem.damagePerWorkout, 2)
        XCTAssertEqual(BossSystem.damagePerDailyComplete, 3)
    }
}
