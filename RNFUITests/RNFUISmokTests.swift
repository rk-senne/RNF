import XCTest

/// Minimal UI smoke test verifying app launch and basic navigation.
/// Satisfies the RNFUITests target requirement.
final class RNFUISmokeTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    /// Verifies the app launches without crashing.
    func testAppLaunches() {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }

    /// Verifies a primary navigation element is visible after launch.
    func testMainViewIsPresented() {
        // The app should present either the login screen or the main tab view
        let loginExists = app.buttons["Sign In"].waitForExistence(timeout: 5)
        let tabBarExists = app.tabBars.firstMatch.waitForExistence(timeout: 5)
        let tryWithoutAccount = app.buttons["Try Without Account"].waitForExistence(timeout: 5)

        // At least one primary view should be visible
        XCTAssertTrue(
            loginExists || tabBarExists || tryWithoutAccount,
            "Expected either login screen or main tab view to be visible"
        )
    }
}
