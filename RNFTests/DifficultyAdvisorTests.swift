import XCTest
@testable import RNF

/// P25-TST-02: Tests for DifficultyAdvisor — threshold evaluation and cooldown rules.
@MainActor
final class DifficultyAdvisorTests: XCTestCase {

    private let goalKey = "rnf_daily_goal"
    private let cooldownKey = "rnf_difficulty_advisor_cooldown"
    private let accountCreatedKey = "rnf_account_created_date"
    private let lastSuggestionKey = "rnf_difficulty_last_suggestion"

    override func setUp() {
        super.setUp()
        clearDefaults()
    }

    override func tearDown() {
        clearDefaults()
        super.tearDown()
    }

    private func clearDefaults() {
        UserDefaults.standard.removeObject(forKey: goalKey)
        UserDefaults.standard.removeObject(forKey: cooldownKey)
        UserDefaults.standard.removeObject(forKey: accountCreatedKey)
        UserDefaults.standard.removeObject(forKey: lastSuggestionKey)
    }

    // MARK: - Increase Threshold (>90% for 7 consecutive days)

    func testSuggestsIncreaseWhenRateAbove90PercentForSevenDays() {
        let rates = makeDailyRates(count: 7, rate: 0.95)
        setAccountAge(days: 30)
        setCurrentGoal(3)

        let suggestion = DifficultyAdvisor.evaluate(
            trailing7DayRates: rates,
            currentGoal: 3,
            accountAgeDays: 30
        )

        XCTAssertEqual(suggestion, .increase)
    }

    func testNoIncreaseWhenRateExactly90Percent() {
        // Exactly 90% does NOT trigger (requires >90%)
        let rates = makeDailyRates(count: 7, rate: 0.90)
        setAccountAge(days: 30)
        setCurrentGoal(3)

        let suggestion = DifficultyAdvisor.evaluate(
            trailing7DayRates: rates,
            currentGoal: 3,
            accountAgeDays: 30
        )

        XCTAssertNotEqual(suggestion, .increase)
    }

    func testNoIncreaseWhenOnlyFiveDaysAbove90() {
        // 5 days at 95%, 2 days at 80% — not 7 consecutive
        var rates = makeDailyRates(count: 5, rate: 0.95)
        rates.append(contentsOf: makeDailyRates(count: 2, rate: 0.80))

        let suggestion = DifficultyAdvisor.evaluate(
            trailing7DayRates: rates,
            currentGoal: 3,
            accountAgeDays: 30
        )

        XCTAssertNotEqual(suggestion, .increase)
    }

    func testNoIncreaseWhenGoalAlreadyAtMaximum() {
        let rates = makeDailyRates(count: 7, rate: 0.95)

        let suggestion = DifficultyAdvisor.evaluate(
            trailing7DayRates: rates,
            currentGoal: 6,  // Maximum
            accountAgeDays: 30
        )

        XCTAssertNotEqual(suggestion, .increase)
    }

    // MARK: - Decrease Threshold (<50% for 3 consecutive days)

    func testSuggestsDecreaseWhenRateBelow50PercentForThreeDays() {
        let rates = makeDailyRates(count: 7, rate: 0.40)
        setCurrentGoal(4)

        let suggestion = DifficultyAdvisor.evaluate(
            trailing7DayRates: rates,
            currentGoal: 4,
            accountAgeDays: 14
        )

        XCTAssertEqual(suggestion, .decrease)
    }

    func testNoDecreaseWhenRateExactly50Percent() {
        // Exactly 50% does NOT trigger (requires <50%)
        let rates = makeDailyRates(count: 7, rate: 0.50)

        let suggestion = DifficultyAdvisor.evaluate(
            trailing7DayRates: rates,
            currentGoal: 4,
            accountAgeDays: 14
        )

        XCTAssertNotEqual(suggestion, .decrease)
    }

    func testNoDecreaseWhenGoalAlreadyAtMinimum() {
        let rates = makeDailyRates(count: 7, rate: 0.30)

        let suggestion = DifficultyAdvisor.evaluate(
            trailing7DayRates: rates,
            currentGoal: 2,  // Minimum
            accountAgeDays: 14
        )

        XCTAssertNotEqual(suggestion, .decrease)
    }

    func testDecreaseRequiresThreeConsecutiveDaysBelow50() {
        // Only 2 consecutive days below 50%, then recovery
        let rates: [Double] = [0.80, 0.70, 0.60, 0.55, 0.45, 0.40, 0.60]

        let suggestion = DifficultyAdvisor.evaluate(
            trailing7DayRates: rates,
            currentGoal: 4,
            accountAgeDays: 14
        )

        // Days 5 and 6 are below 50% but only 2 consecutive
        XCTAssertNotEqual(suggestion, .decrease)
    }

    // MARK: - Cooldown: No Increase During First 14 Days

    func testNoIncreaseBeforeAccountIs14DaysOld() {
        let rates = makeDailyRates(count: 7, rate: 0.98)

        let suggestion = DifficultyAdvisor.evaluate(
            trailing7DayRates: rates,
            currentGoal: 3,
            accountAgeDays: 13  // Only 13 days old
        )

        XCTAssertNotEqual(suggestion, .increase,
                          "Should not suggest increase in first 14 days")
    }

    func testIncreaseAllowedOnDay14() {
        let rates = makeDailyRates(count: 7, rate: 0.95)

        let suggestion = DifficultyAdvisor.evaluate(
            trailing7DayRates: rates,
            currentGoal: 3,
            accountAgeDays: 14
        )

        XCTAssertEqual(suggestion, .increase,
                       "Should allow increase on exactly day 14")
    }

    func testNoIncreaseOnDay1() {
        let rates = makeDailyRates(count: 7, rate: 0.99)

        let suggestion = DifficultyAdvisor.evaluate(
            trailing7DayRates: rates,
            currentGoal: 3,
            accountAgeDays: 1
        )

        XCTAssertNotEqual(suggestion, .increase)
    }

    // MARK: - Cooldown: No Decrease During First 7 Days

    func testNoDecreaseBeforeAccountIs7DaysOld() {
        let rates = makeDailyRates(count: 7, rate: 0.20)

        let suggestion = DifficultyAdvisor.evaluate(
            trailing7DayRates: rates,
            currentGoal: 4,
            accountAgeDays: 6  // Only 6 days old
        )

        XCTAssertNotEqual(suggestion, .decrease,
                          "Should not suggest decrease in first 7 days")
    }

    func testDecreaseAllowedOnDay7() {
        let rates = makeDailyRates(count: 7, rate: 0.30)

        let suggestion = DifficultyAdvisor.evaluate(
            trailing7DayRates: rates,
            currentGoal: 4,
            accountAgeDays: 7
        )

        XCTAssertEqual(suggestion, .decrease,
                       "Should allow decrease on exactly day 7")
    }

    // MARK: - Cooldown After Dismiss

    func testNoneReturnedDuringCooldownPeriod() {
        let rates = makeDailyRates(count: 7, rate: 0.95)

        let suggestion = DifficultyAdvisor.evaluate(
            trailing7DayRates: rates,
            currentGoal: 3,
            accountAgeDays: 30,
            daysSinceLastDismiss: 3  // Within 7-day cooldown
        )

        XCTAssertEqual(suggestion, .none,
                       "Should suppress suggestions during 7-day cooldown after dismiss")
    }

    func testSuggestionReturnsAfterCooldownExpires() {
        let rates = makeDailyRates(count: 7, rate: 0.95)

        let suggestion = DifficultyAdvisor.evaluate(
            trailing7DayRates: rates,
            currentGoal: 3,
            accountAgeDays: 30,
            daysSinceLastDismiss: 8  // Beyond 7-day cooldown
        )

        XCTAssertEqual(suggestion, .increase)
    }

    // MARK: - Goal Boundaries

    func testGoalBoundaryMinimumIs2() {
        XCTAssertEqual(DifficultyAdvisor.minimumGoal, 2)
    }

    func testGoalBoundaryMaximumIs6() {
        XCTAssertEqual(DifficultyAdvisor.maximumGoal, 6)
    }

    // MARK: - Suggestion Priority (Decrease wins over Increase when both apply)

    func testNoneReturnedWhenNoConditionsMet() {
        // Moderate performance — neither increase nor decrease
        let rates = makeDailyRates(count: 7, rate: 0.75)

        let suggestion = DifficultyAdvisor.evaluate(
            trailing7DayRates: rates,
            currentGoal: 4,
            accountAgeDays: 30
        )

        XCTAssertEqual(suggestion, .none)
    }

    // MARK: - Insufficient Data

    func testNoneReturnedWhenLessThanSevenDaysOfData() {
        let rates = makeDailyRates(count: 4, rate: 0.95)

        let suggestion = DifficultyAdvisor.evaluate(
            trailing7DayRates: rates,
            currentGoal: 3,
            accountAgeDays: 30
        )

        XCTAssertEqual(suggestion, .none,
                       "Should not suggest with fewer than 7 days of data")
    }

    // MARK: - Helpers

    private func makeDailyRates(count: Int, rate: Double) -> [Double] {
        Array(repeating: rate, count: count)
    }

    private func setAccountAge(days: Int) {
        let createdDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        UserDefaults.standard.set(createdDate, forKey: accountCreatedKey)
    }

    private func setCurrentGoal(_ goal: Int) {
        UserDefaults.standard.set(goal, forKey: goalKey)
    }
}
