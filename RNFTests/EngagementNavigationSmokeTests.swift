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

}
