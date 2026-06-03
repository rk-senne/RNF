import XCTest
@testable import RNF

final class EvolutionSystemTests: XCTestCase {

    func testCurrentTierStartsAtDisciple() {
        let state = EvolutionSystem.state(for: .placeholder)

        XCTAssertEqual(state.currentTier.rank, .disciple)
        XCTAssertEqual(state.nextTier?.rank, .awakened)
    }

    func testCurrentTierRequiresBothLevelAndStreakMilestones() {
        var profile = Profile.placeholder
        profile.level = 10
        profile.streak = 29

        XCTAssertEqual(EvolutionSystem.currentTier(for: profile).rank, .awakened)

        profile.streak = 30

        XCTAssertEqual(EvolutionSystem.currentTier(for: profile).rank, .ascendant)
    }

    func testCurrentTierUsesXPDerivedLevelWhenProfileLevelLags() {
        var profile = Profile.placeholder
        profile.level = 1
        profile.xp_total = XPSystem.totalXPRequired(for: 15)
        profile.streak = 90

        XCTAssertEqual(EvolutionSystem.currentTier(for: profile).rank, .warlord)
    }

    func testApexHasNoNextTier() {
        var profile = Profile.placeholder
        profile.level = 20
        profile.streak = 180

        let state = EvolutionSystem.state(for: profile)

        XCTAssertEqual(state.currentTier.rank, .apex)
        XCTAssertNil(state.nextTier)
    }

    func testNewlyReachedTierReturnsOnlyForwardProgress() {
        var profile = Profile.placeholder
        profile.level = 5
        profile.streak = 7

        XCTAssertEqual(
            EvolutionSystem.newlyReachedTier(
                previousRank: .disciple,
                profile: profile
            )?.rank,
            .awakened
        )

        XCTAssertNil(
            EvolutionSystem.newlyReachedTier(
                previousRank: .awakened,
                profile: profile
            )
        )
    }

}
