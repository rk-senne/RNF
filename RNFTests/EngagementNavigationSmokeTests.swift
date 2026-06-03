import SwiftUI
import XCTest
@testable import RNF

@MainActor
final class EngagementNavigationSmokeTests: XCTestCase {

    func testAscensionEngagementNavigationStackBuilds() {
        let view = NavigationStack {
            AscensionView()
                .environmentObject(GameState())
        }

        XCTAssertNotNil(view.body)
    }

    func testQuestDestinationBuildsInsideNavigationStack() {
        let view = NavigationStack {
            ContentView()
                .environmentObject(GameState())
        }

        XCTAssertNotNil(view.body)
    }

    func testSkillTreeDestinationBuildsInsideNavigationStack() {
        let game = GameState()
        game.level = SkillTreeSystem.unlockLevel

        let view = NavigationStack {
            SkillTreeView()
                .environmentObject(game)
        }

        XCTAssertNotNil(view.body)
    }

    func testSkillTreeActivePerkSurfaceBuildsForUnlockedProfile() {
        let game = GameState()
        var profile = Profile.placeholder
        profile.level = SkillTreeSystem.unlockLevel
        profile.energy = SkillTreeSystem.unlockLevel

        game.apply(
            profile: profile,
            levelState: XPSystem.levelState(for: profile.xp_total),
            titles: [],
            quests: [],
            dailyGoal: 1,
            dailyCompleted: 0,
            completedHabitIDs: [],
            dailyLog: .today(goal: 1)
        )

        let view = NavigationStack {
            SkillTreeView()
                .environmentObject(game)
        }

        XCTAssertNotNil(view.body)
    }

    func testAscensionActivePerkSummarySurfaceBuilds() {
        let game = GameState()
        var profile = Profile.placeholder
        profile.level = SkillTreeSystem.unlockLevel
        profile.energy = SkillTreeSystem.unlockLevel

        game.apply(
            profile: profile,
            levelState: XPSystem.levelState(for: profile.xp_total),
            titles: [],
            quests: [],
            dailyGoal: 1,
            dailyCompleted: 0,
            completedHabitIDs: [],
            dailyLog: .today(goal: 1)
        )

        let view = NavigationStack {
            AscensionView()
                .environmentObject(game)
        }

        XCTAssertNotNil(view.body)
    }

}
