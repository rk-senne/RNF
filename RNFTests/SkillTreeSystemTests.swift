import XCTest
@testable import RNF

@MainActor
final class SkillTreeSystemTests: XCTestCase {

    func testSkillPointsStartAtLevelTenAndRepeatEveryFiveLevels() {
        XCTAssertEqual(SkillTreeSystem.skillPointsEarned(forLevel: 9), 0)
        XCTAssertEqual(SkillTreeSystem.skillPointsEarned(forLevel: 10), 1)
        XCTAssertEqual(SkillTreeSystem.skillPointsEarned(forLevel: 14), 1)
        XCTAssertEqual(SkillTreeSystem.skillPointsEarned(forLevel: 15), 2)
        XCTAssertEqual(SkillTreeSystem.skillPointsEarned(forLevel: 20), 3)
    }

    func testUnlockStateSubtractsUniqueUnlockedNodesFromEarnedPoints() {
        var profile = Profile.placeholder
        profile.level = 20

        let firstNodeID = UUID()
        let unlocks = [
            makeUnlock(nodeID: firstNodeID),
            makeUnlock(nodeID: firstNodeID),
            makeUnlock(nodeID: UUID())
        ]

        let state = SkillTreeSystem.unlockState(
            profile: profile,
            unlockedSkills: unlocks
        )

        XCTAssertEqual(state.availableSkillPoints, 1)
        XCTAssertEqual(state.unlockedNodeIDs.count, 2)
        XCTAssertTrue(state.unlockedNodeIDs.contains(firstNodeID))
    }

    func testCanUnlockRequiresSkillTreeLevelAndAvailablePoint() {
        let node = makeNode(requiredStat: nil)
        var profile = Profile.placeholder
        profile.level = 9

        XCTAssertFalse(
            SkillTreeSystem.canUnlock(
                node,
                profile: profile,
                state: SkillTreeUnlockState(
                    availableSkillPoints: 1,
                    unlockedNodeIDs: []
                )
            )
        )

        profile.level = 10

        XCTAssertFalse(
            SkillTreeSystem.canUnlock(
                node,
                profile: profile,
                state: SkillTreeUnlockState(
                    availableSkillPoints: 0,
                    unlockedNodeIDs: []
                )
            )
        )
    }

    func testCanUnlockRequiresStatThresholdAndPriorNode() {
        let requiredNodeID = UUID()
        let node = makeNode(
            statType: .focus,
            requiredStat: 8,
            requiredNode: requiredNodeID
        )
        var profile = Profile.placeholder
        profile.level = 10
        profile.focus = 7

        let readyState = SkillTreeUnlockState(
            availableSkillPoints: 1,
            unlockedNodeIDs: [requiredNodeID]
        )

        XCTAssertFalse(
            SkillTreeSystem.canUnlock(
                node,
                profile: profile,
                state: readyState
            )
        )

        profile.focus = 8

        XCTAssertFalse(
            SkillTreeSystem.canUnlock(
                node,
                profile: profile,
                state: SkillTreeUnlockState(
                    availableSkillPoints: 1,
                    unlockedNodeIDs: []
                )
            )
        )
    }

    func testCanUnlockReturnsTrueWhenRequirementsAreMet() {
        let requiredNodeID = UUID()
        let node = makeNode(
            statType: .discipline,
            requiredStat: 5,
            requiredNode: requiredNodeID
        )
        var profile = Profile.placeholder
        profile.level = 10
        profile.discipline = 5

        let state = SkillTreeUnlockState(
            availableSkillPoints: 1,
            unlockedNodeIDs: [requiredNodeID]
        )

        XCTAssertTrue(
            SkillTreeSystem.canUnlock(
                node,
                profile: profile,
                state: state
            )
        )
    }

    private func makeNode(
        statType: SkillTreePath = .strength,
        requiredStat: Int? = 1,
        requiredNode: UUID? = nil
    ) -> SkillTreeNode {

        SkillTreeNode(
            id: UUID(),
            name: "Test Node",
            stat_type: statType,
            tier: .tier1,
            required_stat: requiredStat,
            required_node: requiredNode,
            perk_type: "xp_bonus",
            perk_value: 1
        )
    }

    private func makeUnlock(nodeID: UUID) -> UserSkillUnlock {
        UserSkillUnlock(
            id: UUID(),
            user_id: Profile.placeholder.id,
            skill_node_id: nodeID,
            unlocked_at: Date()
        )
    }

}
