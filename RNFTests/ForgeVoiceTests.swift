import XCTest
@testable import RNF

@MainActor
final class ForgeVoiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "rnf_forge_voice")
        ForgeVoice.resetDailyUsage()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "rnf_forge_voice")
        ForgeVoice.resetDailyUsage()
        super.tearDown()
    }

    // MARK: - Enabled State

    func testIsEnabledReturnsFalseWhenNoPreference() {
        UserDefaults.standard.removeObject(forKey: "rnf_forge_voice")
        XCTAssertFalse(ForgeVoice.isEnabled)
    }

    func testIsEnabledReturnsFalseWhenSetToOff() {
        UserDefaults.standard.set("off", forKey: "rnf_forge_voice")
        XCTAssertFalse(ForgeVoice.isEnabled)
    }

    func testIsEnabledReturnsTrueWhenSetToSystem() {
        UserDefaults.standard.set("system", forKey: "rnf_forge_voice")
        XCTAssertTrue(ForgeVoice.isEnabled)
    }

    func testIsEnabledReturnsTrueWhenSetToOracle() {
        UserDefaults.standard.set("oracle", forKey: "rnf_forge_voice")
        XCTAssertTrue(ForgeVoice.isEnabled)
    }

    // MARK: - Daily Limit

    func testTodayUsageCountStartsAtZero() {
        XCTAssertEqual(ForgeVoice.todayUsageCount, 0)
    }

    func testDailyLimitAllowsTwoUtterances() {
        UserDefaults.standard.set("system", forKey: "rnf_forge_voice")

        // First speak increments count
        ForgeVoice.speak("Test one")
        XCTAssertEqual(ForgeVoice.todayUsageCount, 1)

        // Second speak increments count
        ForgeVoice.speak("Test two")
        XCTAssertEqual(ForgeVoice.todayUsageCount, 2)

        // Third speak should NOT increment (limit reached)
        ForgeVoice.speak("Test three")
        XCTAssertEqual(ForgeVoice.todayUsageCount, 2)
    }

    func testSpeakBypassingLimitDoesNotIncrementCount() {
        UserDefaults.standard.set("system", forKey: "rnf_forge_voice")
        ForgeVoice.speakBypassingLimit("Activated")
        XCTAssertEqual(ForgeVoice.todayUsageCount, 0)
    }

    func testResetDailyUsageClearsCount() {
        UserDefaults.standard.set("system", forKey: "rnf_forge_voice")
        ForgeVoice.speak("Test")
        XCTAssertEqual(ForgeVoice.todayUsageCount, 1)
        ForgeVoice.resetDailyUsage()
        XCTAssertEqual(ForgeVoice.todayUsageCount, 0)
    }

    // MARK: - Disabled State

    func testSpeakDoesNothingWhenDisabled() {
        UserDefaults.standard.set("off", forKey: "rnf_forge_voice")
        ForgeVoice.speak("Should not speak")
        XCTAssertEqual(ForgeVoice.todayUsageCount, 0)
    }

    func testSpeakDoesNothingWithEmptyText() {
        UserDefaults.standard.set("system", forKey: "rnf_forge_voice")
        ForgeVoice.speak("")
        XCTAssertEqual(ForgeVoice.todayUsageCount, 0)
    }
}
