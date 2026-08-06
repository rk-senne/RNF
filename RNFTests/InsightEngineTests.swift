import XCTest
@testable import RNF

/// P25-TST-03: Tests for InsightEngine — pattern detection with mock 28-day data and minimum variance.
@MainActor
final class InsightEngineTests: XCTestCase {

    private let insightsShownKey = "rnf_insights_last_shown"
    private let insightsDataKey = "rnf_insights_history"

    override func setUp() {
        super.setUp()
        clearDefaults()
    }

    override func tearDown() {
        clearDefaults()
        super.tearDown()
    }

    private func clearDefaults() {
        UserDefaults.standard.removeObject(forKey: insightsShownKey)
        UserDefaults.standard.removeObject(forKey: insightsDataKey)
    }

    // MARK: - Best Day Detection

    func testDetectsBestDayWhenOneDay90PercentAndAboveAverage() {
        // Monday at 95% completion, all other days at 60%
        let completionsByDay = makeCompletionsByDay(
            monday: 0.95,
            tuesday: 0.60,
            wednesday: 0.60,
            thursday: 0.60,
            friday: 0.60,
            saturday: 0.60,
            sunday: 0.60
        )

        let insights = InsightEngine.detectPatterns(completionsByDay: completionsByDay)

        let bestDay = insights.first { $0.type == .bestDay }
        XCTAssertNotNil(bestDay, "Should detect Monday as best day")
        XCTAssertEqual(bestDay?.dayOfWeek, 1, "Monday should be identified (1 = Mon)")
    }

    func testNoBestDayWhenVarianceTooLow() {
        // All days at similar rates — less than 15% variance
        let completionsByDay = makeCompletionsByDay(
            monday: 0.75,
            tuesday: 0.72,
            wednesday: 0.74,
            thursday: 0.73,
            friday: 0.71,
            saturday: 0.76,
            sunday: 0.74
        )

        let insights = InsightEngine.detectPatterns(completionsByDay: completionsByDay)

        let bestDay = insights.first { $0.type == .bestDay }
        XCTAssertNil(bestDay, "Should NOT detect best day when variance < 15%")
    }

    // MARK: - Worst Day Detection

    func testDetectsWorstDayWhenOneDayBelow50AndBelowAverage() {
        // Friday at 40%, all other days at 80%
        let completionsByDay = makeCompletionsByDay(
            monday: 0.80,
            tuesday: 0.80,
            wednesday: 0.80,
            thursday: 0.80,
            friday: 0.40,
            saturday: 0.80,
            sunday: 0.80
        )

        let insights = InsightEngine.detectPatterns(completionsByDay: completionsByDay)

        let worstDay = insights.first { $0.type == .worstDay }
        XCTAssertNotNil(worstDay, "Should detect Friday as worst day")
        XCTAssertEqual(worstDay?.dayOfWeek, 5, "Friday should be identified (5 = Fri)")
    }

    func testNoWorstDayWhenAllDaysAbove50() {
        let completionsByDay = makeCompletionsByDay(
            monday: 0.70,
            tuesday: 0.65,
            wednesday: 0.60,
            thursday: 0.55,
            friday: 0.52,
            saturday: 0.68,
            sunday: 0.72
        )

        let insights = InsightEngine.detectPatterns(completionsByDay: completionsByDay)

        let worstDay = insights.first { $0.type == .worstDay }
        XCTAssertNil(worstDay,
                     "Should NOT detect worst day when no day is ≤50%")
    }

    // MARK: - Time Pattern Detection

    func testDetectsTimePatternsWhenAMCompletionsMuchHigher() {
        // AM completion rate 90%, PM completion rate 50%
        let timePattern = InsightEngine.TimePatternData(
            amCompletionRate: 0.90,
            pmCompletionRate: 0.50
        )

        let insights = InsightEngine.detectTimePatterns(data: timePattern)

        let timeInsight = insights.first { $0.type == .timePattern }
        XCTAssertNotNil(timeInsight, "Should detect AM advantage when difference ≥ 25%")
    }

    func testNoTimePatternWhenDifferenceLessThan25Percent() {
        // AM at 70%, PM at 55% — only 15% difference
        let timePattern = InsightEngine.TimePatternData(
            amCompletionRate: 0.70,
            pmCompletionRate: 0.55
        )

        let insights = InsightEngine.detectTimePatterns(data: timePattern)

        let timeInsight = insights.first { $0.type == .timePattern }
        XCTAssertNil(timeInsight, "Should NOT detect time pattern when difference < 25%")
    }

    func testDetectsPMAdvantageWhenPMHigher() {
        // PM completion rate 85%, AM completion rate 55%
        let timePattern = InsightEngine.TimePatternData(
            amCompletionRate: 0.55,
            pmCompletionRate: 0.85
        )

        let insights = InsightEngine.detectTimePatterns(data: timePattern)

        let timeInsight = insights.first { $0.type == .timePattern }
        XCTAssertNotNil(timeInsight, "Should detect PM advantage when difference ≥ 25%")
    }

    // MARK: - Stat Focus Detection

    func testDetectsStatFocusWhenOneStatGrew30PercentMoreThanOthers() {
        let statGrowth: [String: Double] = [
            "strength": 0.50,    // 50% growth — standout
            "discipline": 0.15,
            "focus": 0.10,
            "energy": 0.12,
            "wisdom": 0.08
        ]

        let insights = InsightEngine.detectStatFocus(growthRates: statGrowth)

        let statInsight = insights.first { $0.type == .statFocus }
        XCTAssertNotNil(statInsight, "Should detect stat focus when one stat grew ≥30% more")
        XCTAssertEqual(statInsight?.relatedStat, "strength")
    }

    func testNoStatFocusWhenGrowthIsEvenlyDistributed() {
        let statGrowth: [String: Double] = [
            "strength": 0.20,
            "discipline": 0.18,
            "focus": 0.22,
            "energy": 0.19,
            "wisdom": 0.21
        ]

        let insights = InsightEngine.detectStatFocus(growthRates: statGrowth)

        let statInsight = insights.first { $0.type == .statFocus }
        XCTAssertNil(statInsight, "Should NOT detect stat focus when growth is even")
    }

    // MARK: - Consistency / Streak Detection

    func testDetectsConsistencyWhenSingleHabitStreakExceeds14Days() {
        let streaks: [InsightEngine.HabitStreak] = [
            .init(habitName: "Read 10 pages", currentStreak: 18),
            .init(habitName: "Meditate", currentStreak: 5),
            .init(habitName: "Exercise", currentStreak: 3)
        ]

        let insights = InsightEngine.detectConsistency(streaks: streaks)

        let consistency = insights.first { $0.type == .consistency }
        XCTAssertNotNil(consistency, "Should detect consistency for 18-day streak")
        XCTAssertEqual(consistency?.habitName, "Read 10 pages")
    }

    func testNoConsistencyInsightWhenAllStreaksBelow14() {
        let streaks: [InsightEngine.HabitStreak] = [
            .init(habitName: "Read 10 pages", currentStreak: 10),
            .init(habitName: "Meditate", currentStreak: 12),
            .init(habitName: "Exercise", currentStreak: 8)
        ]

        let insights = InsightEngine.detectConsistency(streaks: streaks)

        let consistency = insights.first { $0.type == .consistency }
        XCTAssertNil(consistency, "Should NOT detect consistency when streaks < 14")
    }

    // MARK: - Minimum Variance Requirements

    func testMinimumVarianceForDayOfWeekInsightIs15Percent() {
        XCTAssertEqual(InsightEngine.minimumDayVariance, 0.15, accuracy: 0.001)
    }

    func testMinimumVarianceForTimePatternIs25Percent() {
        XCTAssertEqual(InsightEngine.minimumTimePatternDifference, 0.25, accuracy: 0.001)
    }

    // MARK: - Novelty Scoring

    func testNoveltyFactorIs1WhenNeverShown() {
        let novelty = InsightEngine.noveltyFactor(
            insightType: .bestDay,
            shownWeeksAgo: nil
        )
        XCTAssertEqual(novelty, 1.0, accuracy: 0.01)
    }

    func testNoveltyFactorIs03WhenShownInLast4Weeks() {
        let novelty = InsightEngine.noveltyFactor(
            insightType: .bestDay,
            shownWeeksAgo: 3
        )
        XCTAssertEqual(novelty, 0.3, accuracy: 0.01)
    }

    func testNoveltyFactorIs0WhenShownLastWeek() {
        let novelty = InsightEngine.noveltyFactor(
            insightType: .bestDay,
            shownWeeksAgo: 1
        )
        XCTAssertEqual(novelty, 0.0, accuracy: 0.01)
    }

    // MARK: - Top Insight Selection

    func testSelectsTopTwoInsightsAboveMinimumThreshold() {
        let candidates: [InsightEngine.ScoredInsight] = [
            .init(type: .bestDay, score: 0.8),
            .init(type: .statFocus, score: 0.6),
            .init(type: .worstDay, score: 0.3),  // Below threshold (0.4)
            .init(type: .timePattern, score: 0.2) // Below threshold
        ]

        let selected = InsightEngine.selectTopInsights(candidates: candidates, maxCount: 2, minimumScore: 0.4)

        XCTAssertEqual(selected.count, 2)
        XCTAssertEqual(selected[0].type, .bestDay)
        XCTAssertEqual(selected[1].type, .statFocus)
    }

    func testReturnsFewerThanTwoWhenInsufficientQualityInsights() {
        let candidates: [InsightEngine.ScoredInsight] = [
            .init(type: .bestDay, score: 0.5),
            .init(type: .worstDay, score: 0.2),
            .init(type: .timePattern, score: 0.1)
        ]

        let selected = InsightEngine.selectTopInsights(candidates: candidates, maxCount: 2, minimumScore: 0.4)

        XCTAssertEqual(selected.count, 1)
        XCTAssertEqual(selected[0].type, .bestDay)
    }

    // MARK: - 28-Day Data Requirement

    func testRequires28DayWindowForFullAnalysis() {
        XCTAssertEqual(InsightEngine.analysisWindowDays, 28)
    }

    // MARK: - Helpers

    private func makeCompletionsByDay(
        monday: Double, tuesday: Double, wednesday: Double,
        thursday: Double, friday: Double, saturday: Double, sunday: Double
    ) -> [Int: Double] {
        return [
            1: monday,
            2: tuesday,
            3: wednesday,
            4: thursday,
            5: friday,
            6: saturday,
            7: sunday
        ]
    }
}
