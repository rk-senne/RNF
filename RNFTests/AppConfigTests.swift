import XCTest
@testable import RNF

@MainActor
final class AppConfigTests: XCTestCase {

    // MARK: - AppConfig

    func testAppConfigReturnsNilWhenKeysMissing() {
        // In test environment, Info.plist won't have these keys
        // so we verify it returns nil gracefully instead of crashing
        // (The old implementation would fatalError in DEBUG)
        // AppConfig.supabaseURL may or may not be nil depending on test Info.plist
        // Key behavior: it doesn't crash
        XCTAssertNoThrow(AppConfig.supabaseURL)
        XCTAssertNoThrow(AppConfig.supabaseAnonKey)
    }

    func testAppConfigIsValidReturnsFalseWhenKeysNil() {
        // If keys are not in test plist, isValid should be false
        if AppConfig.supabaseURL == nil {
            XCTAssertFalse(AppConfig.isValid)
        }
    }

    // MARK: - SupabaseService

    func testSupabaseServiceDoesNotCrashOnInit() {
        // The key test: accessing .shared should never crash
        XCTAssertNoThrow(SupabaseService.shared)
    }

    func testSupabaseServiceReportsConfigurationError() {
        let service = SupabaseService.shared
        // In test environment without valid config, should have an error
        if service.client == nil {
            XCTAssertNotNil(service.configurationError)
            XCTAssertFalse(service.isConfigured)
        }
    }
}

@MainActor
final class FocusCompletionHandlerTests: XCTestCase {

    @MainActor
    func testCompleteAppliesXPThroughProfile() {
        let gameState = GameState()
        gameState.profile = Profile(
            id: UUID(),
            email: nil,
            xp_total: 100,
            level: 1,
            streak: 5,
            forgiveness_tokens: 1,
            morning_notification_time: nil,
            evening_notification_time: nil,
            strength: 5, discipline: 5, focus: 5, energy: 5, wisdom: 5, mind: 5, spirit: 5,
            created_at: nil
        )

        FocusCompletionHandler.complete(xp: 15, gameState: gameState)

        // XP should be applied via profile
        XCTAssertEqual(gameState.profile.xp_total, 115)
        // Stats should be incremented
        XCTAssertEqual(gameState.profile.focus, 6)
        XCTAssertEqual(gameState.profile.mind, 6)
    }
}
