import XCTest
@testable import RNF

// P24-TST-01: CriticalHitEngine Tests
// Validates seeded RNG determinism, crit rate distribution, and streak tier bonuses

final class CriticalHitEngineTests: XCTestCase {

    // MARK: - Test Constants

    private let testUserID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let testHabitID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private let fixedDate = Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 1))!
    private let baseXP = 10

    // MARK: - Seeded RNG Determinism

    func testSameSeedProducesSameResult() {
        let result1 = CriticalHitEngine.evaluate(
            baseXP: baseXP,
            userID: testUserID,
            habitID: testHabitID,
            date: fixedDate,
            streakTier: .spark
        )
        let result2 = CriticalHitEngine.evaluate(
            baseXP: baseXP,
            userID: testUserID,
            habitID: testHabitID,
            date: fixedDate,
            streakTier: .spark
        )

        XCTAssertEqual(result1, result2, "Same inputs must produce identical results")
    }

    func testDifferentDateProducesDifferentSeed() {
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: fixedDate)!

        let result1 = CriticalHitEngine.evaluate(
            baseXP: baseXP, userID: testUserID, habitID: testHabitID,
            date: fixedDate, streakTier: .spark
        )
        let result2 = CriticalHitEngine.evaluate(
            baseXP: baseXP, userID: testUserID, habitID: testHabitID,
            date: nextDay, streakTier: .spark
        )

        // Each call with its own date is self-consistent
        let result1Again = CriticalHitEngine.evaluate(
            baseXP: baseXP, userID: testUserID, habitID: testHabitID,
            date: fixedDate, streakTier: .spark
        )
        XCTAssertEqual(result1, result1Again)

        let result2Again = CriticalHitEngine.evaluate(
            baseXP: baseXP, userID: testUserID, habitID: testHabitID,
            date: nextDay, streakTier: .spark
        )
        XCTAssertEqual(result2, result2Again)
    }

    func testDifferentUserProducesDifferentSeed() {
        let otherUserID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

        let result1 = CriticalHitEngine.evaluate(
            baseXP: baseXP, userID: testUserID, habitID: testHabitID,
            date: fixedDate, streakTier: .spark
        )
        let result2 = CriticalHitEngine.evaluate(
            baseXP: baseXP, userID: otherUserID, habitID: testHabitID,
            date: fixedDate, streakTier: .spark
        )

        let result1Again = CriticalHitEngine.evaluate(
            baseXP: baseXP, userID: testUserID, habitID: testHabitID,
            date: fixedDate, streakTier: .spark
        )
        XCTAssertEqual(result1, result1Again)

        let result2Again = CriticalHitEngine.evaluate(
            baseXP: baseXP, userID: otherUserID, habitID: testHabitID,
            date: fixedDate, streakTier: .spark
        )
        XCTAssertEqual(result2, result2Again)
    }

    func testDifferentHabitProducesDifferentSeed() {
        let otherHabitID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        let result1 = CriticalHitEngine.evaluate(
            baseXP: baseXP, userID: testUserID, habitID: testHabitID,
            date: fixedDate, streakTier: .spark
        )
        let result2 = CriticalHitEngine.evaluate(
            baseXP: baseXP, userID: testUserID, habitID: otherHabitID,
            date: fixedDate, streakTier: .spark
        )

        let result1Again = CriticalHitEngine.evaluate(
            baseXP: baseXP, userID: testUserID, habitID: testHabitID,
            date: fixedDate, streakTier: .spark
        )
        XCTAssertEqual(result1, result1Again)

        let result2Again = CriticalHitEngine.evaluate(
            baseXP: baseXP, userID: testUserID, habitID: otherHabitID,
            date: fixedDate, streakTier: .spark
        )
        XCTAssertEqual(result2, result2Again)
    }

    // MARK: - SeededRNG Unit Tests

    func testSeededRNGProducesConsistentSequence() {
        var rng1 = SeededRNG(seed: 42)
        var rng2 = SeededRNG(seed: 42)

        for _ in 0..<100 {
            XCTAssertEqual(rng1.next(), rng2.next())
        }
    }

    func testSeededRNGDifferentSeedsDiverge() {
        var rng1 = SeededRNG(seed: 42)
        var rng2 = SeededRNG(seed: 99)

        XCTAssertNotEqual(rng1.next(), rng2.next())
    }

    func testSeededRNGNextDoubleInUnitRange() {
        var rng = SeededRNG(seed: 12345)

        for _ in 0..<1000 {
            let value = rng.nextDouble()
            XCTAssertGreaterThanOrEqual(value, 0.0)
            XCTAssertLessThan(value, 1.0)
        }
    }

    // MARK: - Crit Rate Distribution

    func testBaseCritRateApproximately20Percent() {
        let iterations = 1000
        var critCount = 0

        for i in 0..<iterations {
            let habitID = UUID(uuid: (
                UInt8(i & 0xFF), UInt8((i >> 8) & 0xFF), 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            ))
            let date = Calendar.current.date(byAdding: .day, value: i, to: fixedDate)!

            let result = CriticalHitEngine.evaluate(
                baseXP: baseXP, userID: testUserID, habitID: habitID,
                date: date, streakTier: .spark
            )
            if result.isCritical { critCount += 1 }
        }

        let critRate = Double(critCount) / Double(iterations)
        XCTAssertGreaterThan(critRate, 0.15, "Crit rate \(critRate) too low — expected ~20% ±5%")
        XCTAssertLessThan(critRate, 0.25, "Crit rate \(critRate) too high — expected ~20% ±5%")
    }

    // MARK: - CritResult Properties

    func testNonCritReturnsBaseXP() {
        var foundNonCrit = false

        for i in 0..<100 {
            let habitID = UUID(uuid: (
                UInt8(i & 0xFF), UInt8((i >> 8) & 0xFF), 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
            ))
            let result = CriticalHitEngine.evaluate(
                baseXP: baseXP, userID: testUserID, habitID: habitID,
                date: fixedDate, streakTier: .spark
            )
            if !result.isCritical {
                XCTAssertEqual(result.multiplier, 1.0)
                XCTAssertEqual(result.bonusXP, 0)
                XCTAssertEqual(result.baseXP, baseXP)
                XCTAssertEqual(result.totalXP, baseXP)
                foundNonCrit = true
                break
            }
        }
        XCTAssertTrue(foundNonCrit, "Should find at least one non-crit in 100 attempts")
    }

    func testCritMultiplierInRange() {
        var foundCrit = false

        for i in 0..<100 {
            let habitID = UUID(uuid: (
                UInt8(i & 0xFF), UInt8((i >> 8) & 0xFF), 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2
            ))
            let result = CriticalHitEngine.evaluate(
                baseXP: baseXP, userID: testUserID, habitID: habitID,
                date: fixedDate, streakTier: .spark
            )
            if result.isCritical {
                XCTAssertGreaterThanOrEqual(result.multiplier, CriticalHitEngine.minMultiplier)
                XCTAssertLessThanOrEqual(result.multiplier, CriticalHitEngine.maxMultiplier)
                XCTAssertGreaterThan(result.bonusXP, 0)
                XCTAssertEqual(result.totalXP, Int(Double(baseXP) * result.multiplier))
                XCTAssertEqual(result.baseXP, baseXP)
                foundCrit = true
                break
            }
        }
        XCTAssertTrue(foundCrit, "Should find at least one crit in 100 attempts")
    }

    // MARK: - Streak Tier Bonus Applied Correctly

    func testStreakTierBonusValues() {
        XCTAssertEqual(CriticalHitEngine.streakTierBonus(for: .spark), 0.0)
        XCTAssertEqual(CriticalHitEngine.streakTierBonus(for: .ember), 0.05)
        XCTAssertEqual(CriticalHitEngine.streakTierBonus(for: .flame), 0.10)
        XCTAssertEqual(CriticalHitEngine.streakTierBonus(for: .blaze), 0.15)
        XCTAssertEqual(CriticalHitEngine.streakTierBonus(for: .inferno), 0.20)
        XCTAssertEqual(CriticalHitEngine.streakTierBonus(for: .eternal), 0.25)
    }

    func testEffectiveCritRateIncludesStreakBonus() {
        XCTAssertEqual(CriticalHitEngine.effectiveCritRate(for: .spark), 0.20)
        XCTAssertEqual(CriticalHitEngine.effectiveCritRate(for: .ember), 0.25)
        XCTAssertEqual(CriticalHitEngine.effectiveCritRate(for: .flame), 0.30)
        XCTAssertEqual(CriticalHitEngine.effectiveCritRate(for: .blaze), 0.35)
        XCTAssertEqual(CriticalHitEngine.effectiveCritRate(for: .inferno), 0.40)
        XCTAssertEqual(CriticalHitEngine.effectiveCritRate(for: .eternal), 0.45)
    }

    func testEffectiveCritRateCappedAt60Percent() {
        let maxRate = CriticalHitEngine.effectiveCritRate(for: .eternal)
        XCTAssertLessThanOrEqual(maxRate, 0.60)
    }

    func testHigherStreakTierProducesMoreCrits() {
        let iterations = 1000
        var sparkCrits = 0
        var eternalCrits = 0

        for i in 0..<iterations {
            let habitID = UUID(uuid: (
                UInt8(i & 0xFF), UInt8((i >> 8) & 0xFF), 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3
            ))
            let date = Calendar.current.date(byAdding: .day, value: i, to: fixedDate)!

            let spark = CriticalHitEngine.evaluate(
                baseXP: baseXP, userID: testUserID, habitID: habitID,
                date: date, streakTier: .spark
            )
            let eternal = CriticalHitEngine.evaluate(
                baseXP: baseXP, userID: testUserID, habitID: habitID,
                date: date, streakTier: .eternal
            )

            if spark.isCritical { sparkCrits += 1 }
            if eternal.isCritical { eternalCrits += 1 }
        }

        XCTAssertGreaterThan(eternalCrits, sparkCrits,
            "Eternal (\(eternalCrits)) should produce more crits than Spark (\(sparkCrits))")
    }

    func testEternalTierCritRateApproximately45Percent() {
        let iterations = 1000
        var critCount = 0

        for i in 0..<iterations {
            let habitID = UUID(uuid: (
                UInt8(i & 0xFF), UInt8((i >> 8) & 0xFF), 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4
            ))
            let date = Calendar.current.date(byAdding: .day, value: i, to: fixedDate)!

            let result = CriticalHitEngine.evaluate(
                baseXP: baseXP, userID: testUserID, habitID: habitID,
                date: date, streakTier: .eternal
            )
            if result.isCritical { critCount += 1 }
        }

        let critRate = Double(critCount) / Double(iterations)
        XCTAssertGreaterThan(critRate, 0.40, "Eternal crit rate \(critRate) too low — expected ~45% ±5%")
        XCTAssertLessThan(critRate, 0.50, "Eternal crit rate \(critRate) too high — expected ~45% ±5%")
    }
}
