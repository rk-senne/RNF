import XCTest
@testable import RNF

final class IntensitySystemTests: XCTestCase {

    // MARK: - calculateIntensity

    func testIntensity_zeroCompletions_isRest() {
        let result = IntensitySystem.calculateIntensity(
            habitsCompleted: 0, totalHabits: 4, hasWorkout: false, hasReading: false
        )
        XCTAssertEqual(result, .rest)
    }

    func testIntensity_zeroTotalHabits_isRest() {
        let result = IntensitySystem.calculateIntensity(
            habitsCompleted: 0, totalHabits: 0, hasWorkout: true, hasReading: true
        )
        XCTAssertEqual(result, .rest)
    }

    func testIntensity_oneCompletion_isEmber() {
        let result = IntensitySystem.calculateIntensity(
            habitsCompleted: 1, totalHabits: 4, hasWorkout: false, hasReading: false
        )
        XCTAssertEqual(result, .ember)
    }

    func testIntensity_halfCompleted_isFlame() {
        let result = IntensitySystem.calculateIntensity(
            habitsCompleted: 2, totalHabits: 4, hasWorkout: false, hasReading: false
        )
        XCTAssertEqual(result, .flame)
    }

    func testIntensity_allHabitsOnly_isFlame() {
        // All habits but no extras = flame (not blaze)
        let result = IntensitySystem.calculateIntensity(
            habitsCompleted: 4, totalHabits: 4, hasWorkout: false, hasReading: false
        )
        XCTAssertEqual(result, .flame)
    }

    func testIntensity_allHabitsPlusWorkout_isBlaze() {
        let result = IntensitySystem.calculateIntensity(
            habitsCompleted: 4, totalHabits: 4, hasWorkout: true, hasReading: false
        )
        XCTAssertEqual(result, .blaze)
    }

    func testIntensity_allHabitsPlusReading_isBlaze() {
        let result = IntensitySystem.calculateIntensity(
            habitsCompleted: 4, totalHabits: 4, hasWorkout: false, hasReading: true
        )
        XCTAssertEqual(result, .blaze)
    }

    func testIntensity_allHabitsPlusBoth_isInferno() {
        let result = IntensitySystem.calculateIntensity(
            habitsCompleted: 4, totalHabits: 4, hasWorkout: true, hasReading: true
        )
        XCTAssertEqual(result, .inferno)
    }

    func testIntensity_exactlyHalf_isFlame() {
        // 50% threshold: 2/4 = 0.5 which is >= 0.5
        let result = IntensitySystem.calculateIntensity(
            habitsCompleted: 2, totalHabits: 4, hasWorkout: false, hasReading: false
        )
        XCTAssertEqual(result, .flame)
    }

    func testIntensity_belowHalf_isEmber() {
        // 1/3 = 0.33 which is < 0.5
        let result = IntensitySystem.calculateIntensity(
            habitsCompleted: 1, totalHabits: 3, hasWorkout: false, hasReading: false
        )
        XCTAssertEqual(result, .ember)
    }

    // MARK: - xpMultiplier

    func testXPMultiplier_rest_isZero() {
        XCTAssertEqual(IntensitySystem.xpMultiplier(for: .rest), 0.0)
    }

    func testXPMultiplier_ember_isOne() {
        XCTAssertEqual(IntensitySystem.xpMultiplier(for: .ember), 1.0)
    }

    func testXPMultiplier_flame_isOnePointFive() {
        XCTAssertEqual(IntensitySystem.xpMultiplier(for: .flame), 1.5)
    }

    func testXPMultiplier_blaze_isTwo() {
        XCTAssertEqual(IntensitySystem.xpMultiplier(for: .blaze), 2.0)
    }

    func testXPMultiplier_inferno_isThree() {
        XCTAssertEqual(IntensitySystem.xpMultiplier(for: .inferno), 3.0)
    }

    // MARK: - meetsStreakMinimum

    func testStreakMinimum_rest_doesNotMeet() {
        XCTAssertFalse(IntensitySystem.meetsStreakMinimum(.rest))
    }

    func testStreakMinimum_ember_meets() {
        XCTAssertTrue(IntensitySystem.meetsStreakMinimum(.ember))
    }

    func testStreakMinimum_flame_meets() {
        XCTAssertTrue(IntensitySystem.meetsStreakMinimum(.flame))
    }

    func testStreakMinimum_blaze_meets() {
        XCTAssertTrue(IntensitySystem.meetsStreakMinimum(.blaze))
    }

    func testStreakMinimum_inferno_meets() {
        XCTAssertTrue(IntensitySystem.meetsStreakMinimum(.inferno))
    }

    // MARK: - Comparable ordering

    func testIntensityLevels_orderCorrectly() {
        XCTAssertTrue(IntensitySystem.IntensityLevel.rest < .ember)
        XCTAssertTrue(IntensitySystem.IntensityLevel.ember < .flame)
        XCTAssertTrue(IntensitySystem.IntensityLevel.flame < .blaze)
        XCTAssertTrue(IntensitySystem.IntensityLevel.blaze < .inferno)
    }

    // MARK: - colorName

    func testColorName_allLevelsHaveValues() {
        for level in IntensitySystem.IntensityLevel.allCases {
            let name = IntensitySystem.colorName(for: level)
            XCTAssertFalse(name.isEmpty, "Color name missing for \(level)")
        }
    }
}
