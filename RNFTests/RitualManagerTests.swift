import XCTest
@testable import RNF

@MainActor
final class RitualManagerTests: XCTestCase {

    private var sut: RitualManager!

    override func setUp() {
        super.setUp()
        sut = RitualManager()
        // Clear relevant UserDefaults keys
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "rnf_last_intent_date")
        defaults.removeObject(forKey: "rnf_today_focus_stat")
    }

    func testCheckMorningIntention_showsWhenNotSetToday() {
        XCTAssertFalse(sut.showMorningIntention)
        sut.checkMorningIntention()
        XCTAssertTrue(sut.showMorningIntention)
    }

    func testSetIntention_dismissesMorning() {
        sut.showMorningIntention = true
        sut.setIntention(stat: "Focus")
        XCTAssertFalse(sut.showMorningIntention)
        XCTAssertEqual(sut.todayFocusStat, "Focus")
    }

    func testSetIntention_preventsSecondShow() {
        sut.setIntention(stat: "Strength")
        sut.checkMorningIntention()
        XCTAssertFalse(sut.showMorningIntention)
    }

    func testDismissMorning_preventsSecondShow() {
        sut.dismissMorning()
        sut.checkMorningIntention()
        XCTAssertFalse(sut.showMorningIntention)
    }

    func testIntentMultiplier_emptyStatReturns1() {
        XCTAssertEqual(sut.intentMultiplier, 1.0)
    }

    func testIntentMultiplier_withStatReturns110() {
        sut.setIntention(stat: "Discipline")
        XCTAssertEqual(sut.intentMultiplier, 1.10)
    }

    func testTriggerEveningReflection_showsOnce() {
        sut.triggerEveningReflection()
        XCTAssertTrue(sut.showEveningReflection)
        sut.dismissEvening()
        XCTAssertFalse(sut.showEveningReflection)
        // Second trigger same day should not show
        sut.triggerEveningReflection()
        XCTAssertFalse(sut.showEveningReflection)
    }

    override func tearDown() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "rnf_last_intent_date")
        defaults.removeObject(forKey: "rnf_today_focus_stat")
        // Clean evening key
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let today = f.string(from: Date())
        defaults.removeObject(forKey: "rnf_evening_shown_\(today)")
        super.tearDown()
    }
}
