import XCTest
@testable import RNF

@MainActor
final class XPSystemTests: XCTestCase {

    func testLevelStateUsesThresholdFloors() {
        let startingState = XPSystem.levelState(for: 0)
        XCTAssertEqual(startingState.totalXP, 0)
        XCTAssertEqual(startingState.level, 1)
        XCTAssertEqual(startingState.xpIntoLevel, 0)
        XCTAssertEqual(startingState.xpToNext, 200)
        XCTAssertFalse(startingState.leveledUp)

        let levelTwoState = XPSystem.levelState(for: 200)
        XCTAssertEqual(levelTwoState.totalXP, 200)
        XCTAssertEqual(levelTwoState.level, 2)
        XCTAssertEqual(levelTwoState.xpIntoLevel, 0)
        XCTAssertEqual(levelTwoState.xpToNext, 250)

        let levelThreeState = XPSystem.levelState(for: 450)
        XCTAssertEqual(levelThreeState.totalXP, 450)
        XCTAssertEqual(levelThreeState.level, 3)
        XCTAssertEqual(levelThreeState.xpIntoLevel, 0)
        XCTAssertEqual(levelThreeState.xpToNext, 350)
    }

    func testApplyXPCarriesRemainderAcrossThreshold() {
        let state = XPSystem.applyXP(totalXP: 190, gainedXP: 25)

        XCTAssertEqual(state.totalXP, 215)
        XCTAssertEqual(state.level, 2)
        XCTAssertEqual(state.xpIntoLevel, 15)
        XCTAssertEqual(state.xpToNext, 250)
        XCTAssertTrue(state.leveledUp)
    }

    func testApplyXPDoesNotLevelUpBeforeThreshold() {
        let state = XPSystem.applyXP(totalXP: 100, gainedXP: 50)

        XCTAssertEqual(state.totalXP, 150)
        XCTAssertEqual(state.level, 1)
        XCTAssertEqual(state.xpIntoLevel, 150)
        XCTAssertEqual(state.xpToNext, 200)
        XCTAssertFalse(state.leveledUp)
    }

}
