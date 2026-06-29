import XCTest
@testable import RNF

final class AchievementEvaluationTests: XCTestCase {

    func testEvaluatesStreakAchievements() {
        let service = AchievementService()
        let profile = makeProfile(level: 10, streak: 30)
        let stats = AchievementService.UserStats(totalHabitsCompleted: 10, totalWorkouts: 5, totalReadings: 3, bossesDefeated: 0)

        let eligible = service.evaluate(profile: profile, stats: stats)
        let ids = eligible.map(\.id)

        XCTAssertTrue(ids.contains("streak_7"))
        XCTAssertTrue(ids.contains("streak_30"))
        XCTAssertFalse(ids.contains("streak_90"))
    }

    func testEvaluatesLevelAchievements() {
        let service = AchievementService()
        let profile = makeProfile(level: 10, streak: 0)
        let stats = AchievementService.UserStats(totalHabitsCompleted: 0, totalWorkouts: 0, totalReadings: 0, bossesDefeated: 0)

        let eligible = service.evaluate(profile: profile, stats: stats)
        let ids = eligible.map(\.id)

        XCTAssertTrue(ids.contains("level_5"))
        XCTAssertTrue(ids.contains("level_10"))
        XCTAssertFalse(ids.contains("level_20"))
    }

    func testEvaluatesHabitCountAchievements() {
        let service = AchievementService()
        let profile = makeProfile(level: 1, streak: 0)
        let stats = AchievementService.UserStats(totalHabitsCompleted: 50, totalWorkouts: 0, totalReadings: 0, bossesDefeated: 0)

        let eligible = service.evaluate(profile: profile, stats: stats)
        let ids = eligible.map(\.id)

        XCTAssertTrue(ids.contains("habits_50"))
        XCTAssertFalse(ids.contains("habits_500"))
    }

    func testMasteryTierCalculation() {
        XCTAssertEqual(MasteryPathService.tierForXP(0), 1)
        XCTAssertEqual(MasteryPathService.tierForXP(499), 1)
        XCTAssertEqual(MasteryPathService.tierForXP(500), 2)
        XCTAssertEqual(MasteryPathService.tierForXP(1999), 2)
        XCTAssertEqual(MasteryPathService.tierForXP(2000), 3)
        XCTAssertEqual(MasteryPathService.tierForXP(9999), 3)
    }

    private func makeProfile(level: Int, streak: Int) -> Profile {
        Profile(
            id: UUID(), email: "test@test.com", xp_total: 0, level: level, streak: streak,
            forgiveness_tokens: 0, morning_notification_time: nil, evening_notification_time: nil,
            strength: 1, discipline: 1, focus: 1, energy: 1, wisdom: 1, mind: 1, spirit: 1, created_at: nil
        )
    }
}
