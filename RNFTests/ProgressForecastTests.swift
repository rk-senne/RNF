import XCTest
@testable import RNF

final class ProgressForecastTests: XCTestCase {

    // MARK: - Helper

    private func makeDailyLog(habitsCompleted: Int, date: Date = Date()) -> DailyLog {
        DailyLog(
            id: UUID(),
            user_id: UUID(),
            date: date,
            habits_completed: habitsCompleted,
            habits_required: 4,
            workout_completed: false,
            reading_completed: false,
            forgiveness_used: false,
            xp_earned: habitsCompleted * 10,
            status: habitsCompleted >= 4 ? .complete : .partial,
            created_at: nil
        )
    }

    // MARK: - calculatePace

    func testCalculatePace_emptyLogs_returnsZero() {
        let pace = ProgressForecast.calculatePace(logs: [], window: 7)
        XCTAssertEqual(pace, 0.0)
    }

    func testCalculatePace_consistentLogs_returnsAverage() {
        let logs = (0..<7).map { _ in makeDailyLog(habitsCompleted: 3) }
        let pace = ProgressForecast.calculatePace(logs: logs, window: 7)
        XCTAssertEqual(pace, 3.0, accuracy: 0.01)
    }

    func testCalculatePace_varyingLogs_returnsCorrectAverage() {
        let logs = [
            makeDailyLog(habitsCompleted: 4),
            makeDailyLog(habitsCompleted: 2),
            makeDailyLog(habitsCompleted: 3),
            makeDailyLog(habitsCompleted: 1),
        ]
        let pace = ProgressForecast.calculatePace(logs: logs, window: 7)
        // (4+2+3+1) / 4 = 2.5
        XCTAssertEqual(pace, 2.5, accuracy: 0.01)
    }

    func testCalculatePace_windowLargerThanLogs_usesAllLogs() {
        let logs = [makeDailyLog(habitsCompleted: 4), makeDailyLog(habitsCompleted: 2)]
        let pace = ProgressForecast.calculatePace(logs: logs, window: 7)
        XCTAssertEqual(pace, 3.0, accuracy: 0.01)
    }

    // MARK: - assessRisk

    func testAssessRisk_goodPace_onTrack() {
        let risk = ProgressForecast.assessRisk(pace7Day: 3.5, trend: 0.1)
        XCTAssertEqual(risk, .onTrack)
    }

    func testAssessRisk_lowPace_atRisk() {
        let risk = ProgressForecast.assessRisk(pace7Day: 0.5, trend: 0.0)
        XCTAssertEqual(risk, .atRisk)
    }

    func testAssessRisk_decliningTrend_slipping() {
        let risk = ProgressForecast.assessRisk(pace7Day: 2.0, trend: -0.8)
        XCTAssertEqual(risk, .slipping)
    }

    func testAssessRisk_lowPaceTrumpsTrend() {
        // At risk takes priority over slipping
        let risk = ProgressForecast.assessRisk(pace7Day: 0.3, trend: -1.0)
        XCTAssertEqual(risk, .atRisk)
    }

    // MARK: - daysToNextStreakTier

    func testDaysToNextTier_spark_returns7MinusCurrent() {
        XCTAssertEqual(ProgressForecast.daysToNextStreakTier(currentStreak: 3), 4)
    }

    func testDaysToNextTier_ember_returns14MinusCurrent() {
        XCTAssertEqual(ProgressForecast.daysToNextStreakTier(currentStreak: 10), 4)
    }

    func testDaysToNextTier_flame_returns30MinusCurrent() {
        XCTAssertEqual(ProgressForecast.daysToNextStreakTier(currentStreak: 20), 10)
    }

    func testDaysToNextTier_eternal_returnsNil() {
        XCTAssertNil(ProgressForecast.daysToNextStreakTier(currentStreak: 100))
    }

    // MARK: - projectStreakTier

    func testProjectStreakTier_30DaysFromSpark() {
        let tier = ProgressForecast.projectStreakTier(currentStreak: 0, daysAhead: 30)
        XCTAssertEqual(tier, "Blaze")
    }

    func testProjectStreakTier_30DaysFromFlame() {
        let tier = ProgressForecast.projectStreakTier(currentStreak: 20, daysAhead: 30)
        XCTAssertEqual(tier, "Blaze")
    }

    // MARK: - Full calculate

    func testCalculate_fullProjection_returnsValidResult() {
        let logs = (0..<14).map { _ in makeDailyLog(habitsCompleted: 3) }

        let projection = ProgressForecast.calculate(
            recentLogs: logs,
            currentLevel: 5,
            currentXP: 1000,
            currentStreak: 10
        )

        XCTAssertEqual(projection.currentPace, 3.0, accuracy: 0.01)
        XCTAssertEqual(projection.riskLevel, .onTrack)
        XCTAssertNotNil(projection.projectedNextLevelDate)
        XCTAssertEqual(projection.daysToNextTier, 4) // 14 - 10
    }

    func testCalculate_emptyLogs_atRisk() {
        let projection = ProgressForecast.calculate(
            recentLogs: [],
            currentLevel: 1,
            currentXP: 0,
            currentStreak: 0
        )

        XCTAssertEqual(projection.currentPace, 0.0)
        XCTAssertEqual(projection.riskLevel, .atRisk)
        XCTAssertNil(projection.projectedNextLevelDate)
    }
}
