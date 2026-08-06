import XCTest
@testable import RNF

@MainActor
final class PillarStreakServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "rnf_pillar_streaks")
        UserDefaults.standard.removeObject(forKey: "rnf_pillar_dates")
    }

    func testLoadReturnsDefaultWhenEmpty() {
        let streaks = PillarStreakService.load()
        XCTAssertEqual(streaks.habits, 0)
        XCTAssertEqual(streaks.workouts, 0)
        XCTAssertEqual(streaks.reading, 0)
        XCTAssertEqual(streaks.focus, 0)
        XCTAssertEqual(streaks.overall, 0)
    }

    func testSaveAndLoad() {
        var streaks = PillarStreaks()
        streaks.habits = 5
        streaks.workouts = 3
        PillarStreakService.save(streaks)

        let loaded = PillarStreakService.load()
        XCTAssertEqual(loaded.habits, 5)
        XCTAssertEqual(loaded.workouts, 3)
    }

    func testRecordCompletionIncrementsStreak() {
        PillarStreakService.recordCompletion(pillar: "habits")
        let streaks = PillarStreakService.load()
        XCTAssertEqual(streaks.habits, 1)
    }
}

@MainActor
final class WeeklyReportServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "rnf_weekly_report_shown")
    }

    func testMarkShownPreventsReshow() {
        // Only meaningful on Mondays, but markShown should persist
        WeeklyReportService.markShown()
        let weekID = Calendar.current.component(.weekOfYear, from: Date())
        let stored = UserDefaults.standard.integer(forKey: "rnf_weekly_report_shown")
        XCTAssertEqual(stored, weekID)
    }

    func testGenerateReport() {
        let profile = Profile.placeholder
        let report = WeeklyReportService.generate(profile: profile, streak: 5)
        XCTAssertEqual(report.daysActive, 5)
        XCTAssertEqual(report.habitsCompleted, 20)
        XCTAssertEqual(report.xpEarned, 400)
        XCTAssertEqual(report.streakLength, 5)
        XCTAssertEqual(report.bestDayXP, 180)
    }
}
