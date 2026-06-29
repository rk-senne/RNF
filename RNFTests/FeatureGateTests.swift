import XCTest
@testable import RNF

final class FeatureGateTests: XCTestCase {

    func testBossUnlocksAtLevel10With14DayStreak() {
        XCTAssertFalse(FeatureGate.isUnlocked(.bossChallenge, level: 9, streak: 14, hasCompletedChallenge: false))
        XCTAssertFalse(FeatureGate.isUnlocked(.bossChallenge, level: 10, streak: 13, hasCompletedChallenge: false))
        XCTAssertTrue(FeatureGate.isUnlocked(.bossChallenge, level: 10, streak: 14, hasCompletedChallenge: false))
    }

    func testAchievementsUnlockAtLevel5With7DayStreak() {
        XCTAssertFalse(FeatureGate.isUnlocked(.achievements, level: 4, streak: 7, hasCompletedChallenge: false))
        XCTAssertTrue(FeatureGate.isUnlocked(.achievements, level: 5, streak: 7, hasCompletedChallenge: false))
    }

    func testMasteryRequiresChallengeCompletion() {
        XCTAssertFalse(FeatureGate.isUnlocked(.masteryPaths, level: 15, streak: 30, hasCompletedChallenge: false))
        XCTAssertTrue(FeatureGate.isUnlocked(.masteryPaths, level: 15, streak: 30, hasCompletedChallenge: true))
    }

    func testUnlockedFeaturesReturnsCorrectSet() {
        let features = FeatureGate.unlockedFeatures(level: 20, streak: 90, hasCompletedChallenge: true)
        XCTAssertTrue(features.contains(.bossChallenge))
        XCTAssertTrue(features.contains(.achievements))
        XCTAssertTrue(features.contains(.masteryPaths))
        XCTAssertTrue(features.contains(.advancedTitles))
        XCTAssertTrue(features.contains(.guilds))
        XCTAssertTrue(features.contains(.leaderboards))
        XCTAssertTrue(features.contains(.socialChallenges))
    }

    func testNewUserHasNoUnlockedFeatures() {
        let features = FeatureGate.unlockedFeatures(level: 1, streak: 0, hasCompletedChallenge: false)
        XCTAssertTrue(features.isEmpty)
    }
}
