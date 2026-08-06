import XCTest
@testable import RNF

@MainActor
final class PerkSystemTests: XCTestCase {

    func testActivePerksAggregatesUnlockedSkillEffects() {
        let xpNode = makeNode(
            name: "XP Surge",
            statType: .energy,
            perkType: "xp_multiplier",
            perkValue: 10
        )
        let statNode = makeNode(
            name: "Focused Mind",
            statType: .focus,
            perkType: "stat_bonus",
            perkValue: 2
        )
        let questNode = makeNode(
            name: "Quest Bounty",
            statType: .discipline,
            perkType: "quest_reward_bonus",
            perkValue: 5
        )
        let streakNode = makeNode(
            name: "Shielded Streak",
            statType: .spirit,
            perkType: "streak_protection",
            perkValue: 1
        )
        let lockedNode = makeNode(
            name: "Locked",
            statType: .strength,
            perkType: "xp_multiplier",
            perkValue: 50
        )

        let summary = PerkSystem.activePerks(
            skillNodes: [xpNode, statNode, questNode, streakNode, lockedNode],
            unlockedSkills: [
                makeUnlock(nodeID: xpNode.id),
                makeUnlock(nodeID: statNode.id),
                makeUnlock(nodeID: questNode.id),
                makeUnlock(nodeID: streakNode.id)
            ]
        )

        XCTAssertEqual(summary.effects.count, 4)
        XCTAssertEqual(summary.unlockedSkillNodeIDs.count, 4)
        XCTAssertEqual(summary.xpMultiplierPercent, 10)
        XCTAssertEqual(summary.statBonuses[.focus], 2)
        XCTAssertEqual(summary.questRewardBonus, 5)
        XCTAssertEqual(summary.streakProtectionCount, 1)
        XCTAssertFalse(summary.unlockedSkillNodeIDs.contains(lockedNode.id))
    }

    func testModifiedXPRewardAppliesMultiplierAndDailyCap() {
        let summary = ActivePerkSummary(
            effects: [],
            unlockedSkillNodeIDs: [],
            xpMultiplierPercent: 50,
            statBonuses: [:],
            questRewardBonus: 0,
            streakProtectionCount: 0
        )

        XCTAssertEqual(
            PerkSystem.modifiedXPReward(
                baseXP: 20,
                activePerks: summary,
                currentDailyXP: 0,
                dailyCap: 100
            ),
            30
        )

        XCTAssertEqual(
            PerkSystem.modifiedXPReward(
                baseXP: 20,
                activePerks: summary,
                currentDailyXP: 85,
                dailyCap: 100
            ),
            15
        )
    }

    func testModifiedStatAndQuestRewardsApplyBonusesSafely() {
        let summary = ActivePerkSummary(
            effects: [],
            unlockedSkillNodeIDs: [],
            xpMultiplierPercent: 0,
            statBonuses: [.focus: 2],
            questRewardBonus: 7,
            streakProtectionCount: 0
        )

        XCTAssertEqual(
            PerkSystem.modifiedStatReward(
                baseStatGain: 1,
                statType: .focus,
                activePerks: summary,
                currentStatValue: 90
            ),
            3
        )

        XCTAssertEqual(
            PerkSystem.modifiedStatReward(
                baseStatGain: 1,
                statType: .focus,
                activePerks: summary,
                currentStatValue: 99
            ),
            1
        )

        XCTAssertEqual(
            PerkSystem.modifiedQuestReward(
                baseReward: 10,
                activePerks: summary
            ),
            17
        )
    }

    func testStreakProtectionUsesPerkOrStoredToken() {
        var missedLog = DailyLog.today(goal: 1)
        missedLog.status = .missed

        let summary = ActivePerkSummary(
            effects: [],
            unlockedSkillNodeIDs: [],
            xpMultiplierPercent: 0,
            statBonuses: [:],
            questRewardBonus: 0,
            streakProtectionCount: 1
        )

        XCTAssertTrue(
            PerkSystem.canUseStreakProtection(
                dailyLog: missedLog,
                activePerks: summary,
                forgivenessTokens: 0
            )
        )

        missedLog.forgiveness_used = true

        XCTAssertFalse(
            PerkSystem.canUseStreakProtection(
                dailyLog: missedLog,
                activePerks: summary,
                forgivenessTokens: 1
            )
        )
    }

    private func makeNode(
        name: String,
        statType: SkillTreePath,
        perkType: String,
        perkValue: Int
    ) -> SkillTreeNode {

        SkillTreeNode(
            id: UUID(),
            name: name,
            stat_type: statType,
            tier: .tier1,
            required_stat: nil,
            required_node: nil,
            perk_type: perkType,
            perk_value: perkValue
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
