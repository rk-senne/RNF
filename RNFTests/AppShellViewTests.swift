import XCTest
@testable import RNF

@MainActor
final class AppShellViewTests: XCTestCase {

    func testRouteMapsLaunchStatesToExistingRootSurfaces() {
        XCTAssertEqual(AppShellRoute(appState: .loggedOut), .auth)
        XCTAssertEqual(AppShellRoute(appState: .onboardingNotifications), .notifications)
        XCTAssertEqual(AppShellRoute(appState: .onboardingCommitment), .commitment)
        XCTAssertEqual(AppShellRoute(appState: .challengeComplete), .challengeComplete)
        XCTAssertEqual(AppShellRoute(appState: .authenticated), .mainTabs)
        XCTAssertEqual(AppShellRoute(appState: .challengeActive), .mainTabs)
        XCTAssertEqual(AppShellRoute(appState: .dailyProgress), .mainTabs)
        XCTAssertEqual(AppShellRoute(appState: .dayComplete), .mainTabs)
    }

    func testAppShellAcceptsInjectedAppStateManager() {
        let manager = AppStateManager(initialState: .loggedOut)

        _ = AppShellView(appStateManager: manager)
    }

}
