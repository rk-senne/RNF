import XCTest
@testable import RNF

final class SparkAchievementTriggerTests: XCTestCase {
    
    // MARK: - Achievement ID Mapping
    
    func testAchievementID_mapsCorrectly() {
        XCTAssertEqual(SparkAchievementTrigger.achievementID(for: .firstHabitCompleted), "spark_first_habit")
        XCTAssertEqual(SparkAchievementTrigger.achievementID(for: .archetypeChosen), "spark_archetype")
        XCTAssertEqual(SparkAchievementTrigger.achievementID(for: .dailyGoalSet), "spark_goal_set")
        XCTAssertEqual(SparkAchievementTrigger.achievementID(for: .firstReadingOpened), "spark_first_read")
        XCTAssertEqual(SparkAchievementTrigger.achievementID(for: .firstWorkoutLogged), "spark_first_workout")
    }
    
    // MARK: - XP Rewards
    
    func testXPRewards_correctValues() {
        XCTAssertEqual(SparkAchievementTrigger.xpReward(for: .firstHabitCompleted), 15)
        XCTAssertEqual(SparkAchievementTrigger.xpReward(for: .archetypeChosen), 10)
        XCTAssertEqual(SparkAchievementTrigger.xpReward(for: .dailyGoalSet), 5)
        XCTAssertEqual(SparkAchievementTrigger.xpReward(for: .firstReadingOpened), 5)
        XCTAssertEqual(SparkAchievementTrigger.xpReward(for: .firstWorkoutLogged), 10)
    }
    
    // MARK: - Spark Achievement Definitions
    
    func testSparkAchievements_has5Entries() {
        XCTAssertEqual(SparkAchievementTrigger.sparkAchievements.count, 5)
    }
    
    func testSparkAchievements_allHaveUniqueIDs() {
        let ids = SparkAchievementTrigger.sparkAchievements.map { $0.id }
        XCTAssertEqual(Set(ids).count, ids.count)
    }
    
    func testSparkAchievements_allHaveIconNames() {
        for achievement in SparkAchievementTrigger.sparkAchievements {
            XCTAssertFalse(achievement.iconName.isEmpty, "Achievement \(achievement.id) missing icon")
        }
    }
    
    // MARK: - All SparkEvents have a mapping
    
    func testAllSparkEvents_haveAchievementMapping() {
        let events: [SparkEvent] = [
            .firstHabitCompleted,
            .archetypeChosen,
            .dailyGoalSet,
            .firstReadingOpened,
            .firstWorkoutLogged
        ]
        for event in events {
            let id = SparkAchievementTrigger.achievementID(for: event)
            XCTAssertFalse(id.isEmpty)
            XCTAssertTrue(id.hasPrefix("spark_"))
        }
    }
}
