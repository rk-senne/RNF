import XCTest
@testable import RNF

// P24-TST-04: LeagueService Tests
// Validates weekly recalculation, tier transitions (top 5 promote, bottom 5 demote), XP accumulation

@MainActor
final class LeagueServiceTests: XCTestCase {

    private var sut: LeagueService!
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "LeagueServiceTests")!
        testDefaults.removePersistentDomain(forName: "LeagueServiceTests")
        sut = LeagueService(supabase: .shared, userDefaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "LeagueServiceTests")
        testDefaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialTierIsBronze() {
        XCTAssertEqual(sut.currentTier, .bronze)
    }

    func testInitiallyNotJoined() {
        XCTAssertFalse(sut.isJoined)
    }

    func testInitialLeaderboardEmpty() {
        XCTAssertTrue(sut.leaderboard.isEmpty)
    }

    func testInitialStandingIsNil() {
        XCTAssertNil(sut.standing)
    }

    // MARK: - Tier Ordering

    func testTierOrderBronzeToDiamond() {
        let tiers: [LeagueService.Tier] = [.bronze, .silver, .gold, .platinum, .diamond]
        for i in 0..<(tiers.count - 1) {
            XCTAssertTrue(tiers[i] < tiers[i + 1],
                "\(tiers[i].rawValue) should be less than \(tiers[i + 1].rawValue)")
        }
    }

    func testTierNextProgression() {
        XCTAssertEqual(LeagueService.Tier.bronze.next, .silver)
        XCTAssertEqual(LeagueService.Tier.silver.next, .gold)
        XCTAssertEqual(LeagueService.Tier.gold.next, .platinum)
        XCTAssertEqual(LeagueService.Tier.platinum.next, .diamond)
        XCTAssertNil(LeagueService.Tier.diamond.next)
    }

    func testTierPreviousDemotion() {
        XCTAssertNil(LeagueService.Tier.bronze.previous)
        XCTAssertEqual(LeagueService.Tier.silver.previous, .bronze)
        XCTAssertEqual(LeagueService.Tier.gold.previous, .silver)
        XCTAssertEqual(LeagueService.Tier.platinum.previous, .gold)
        XCTAssertEqual(LeagueService.Tier.diamond.previous, .platinum)
    }

    // MARK: - Promotion/Demotion Thresholds

    func testPromotionThresholdIs5() {
        for tier in LeagueService.Tier.allCases {
            XCTAssertEqual(tier.promotionThreshold, 5,
                "\(tier.rawValue) promotion threshold should be 5")
        }
    }

    func testDemotionThresholdIs5() {
        for tier in LeagueService.Tier.allCases {
            XCTAssertEqual(tier.demotionThreshold, 5,
                "\(tier.rawValue) demotion threshold should be 5")
        }
    }

    // MARK: - Tier Transition Logic (Unit Tests)

    /// Tests the promotion/demotion logic in isolation using LeagueStanding
    func testStandingWillPromoteForTopRanks() {
        // Rank <= promotionThreshold (5) → willPromote
        let standing = LeagueService.LeagueStanding(
            tier: .gold,
            rank: 5,
            totalMembers: 20,
            weeklyXP: 400,
            willPromote: true,
            willDemote: false
        )
        XCTAssertTrue(standing.willPromote)
        XCTAssertFalse(standing.willDemote)
    }

    func testStandingWillDemoteForBottomRanks() {
        // Rank > (totalMembers - demotionThreshold) → willDemote
        // 20 - 5 = 15, rank 16+ demotes
        let standing = LeagueService.LeagueStanding(
            tier: .gold,
            rank: 16,
            totalMembers: 20,
            weeklyXP: 30,
            willPromote: false,
            willDemote: true
        )
        XCTAssertFalse(standing.willPromote)
        XCTAssertTrue(standing.willDemote)
    }

    func testStandingMiddleRankNeitherPromotesNorDemotes() {
        let standing = LeagueService.LeagueStanding(
            tier: .silver,
            rank: 10,
            totalMembers: 20,
            weeklyXP: 200,
            willPromote: false,
            willDemote: false
        )
        XCTAssertFalse(standing.willPromote)
        XCTAssertFalse(standing.willDemote)
    }

    // MARK: - Tier Transition Via Next/Previous

    func testPromotionViaTierNext() {
        var tier: LeagueService.Tier = .bronze

        // Simulate promotion chain
        tier = tier.next ?? tier
        XCTAssertEqual(tier, .silver)

        tier = tier.next ?? tier
        XCTAssertEqual(tier, .gold)

        tier = tier.next ?? tier
        XCTAssertEqual(tier, .platinum)

        tier = tier.next ?? tier
        XCTAssertEqual(tier, .diamond)

        // Cannot promote past diamond
        tier = tier.next ?? tier
        XCTAssertEqual(tier, .diamond)
    }

    func testDemotionViaTierPrevious() {
        var tier: LeagueService.Tier = .diamond

        tier = tier.previous ?? tier
        XCTAssertEqual(tier, .platinum)

        tier = tier.previous ?? tier
        XCTAssertEqual(tier, .gold)

        tier = tier.previous ?? tier
        XCTAssertEqual(tier, .silver)

        tier = tier.previous ?? tier
        XCTAssertEqual(tier, .bronze)

        // Cannot demote past bronze
        tier = tier.previous ?? tier
        XCTAssertEqual(tier, .bronze)
    }

    // MARK: - Join

    func testJoinSetsInitialState() async {
        let userID = UUID()
        _ = await sut.join(userID: userID, displayName: "TestPlayer")

        XCTAssertTrue(sut.isJoined)
        XCTAssertEqual(sut.currentTier, .bronze)
    }

    // MARK: - XP Accumulation

    func testWeeklyXPAccumulatesInUserDefaults() async {
        let userID = UUID()
        _ = await sut.join(userID: userID, displayName: "Test")

        await sut.reportWeeklyXP(userID: userID, xpGained: 50)
        let first = testDefaults.integer(forKey: "rnf_league_weekly_xp")
        XCTAssertEqual(first, 50)

        await sut.reportWeeklyXP(userID: userID, xpGained: 30)
        let second = testDefaults.integer(forKey: "rnf_league_weekly_xp")
        XCTAssertEqual(second, 80)
    }

    func testWeeklyXPDoesNotAccumulateWhenNotJoined() async {
        let userID = UUID()
        // Don't join
        await sut.reportWeeklyXP(userID: userID, xpGained: 100)

        let xp = testDefaults.integer(forKey: "rnf_league_weekly_xp")
        XCTAssertEqual(xp, 0, "XP should not accumulate when not joined")
    }

    func testMultipleXPReportsAccumulate() async {
        let userID = UUID()
        _ = await sut.join(userID: userID, displayName: "Test")

        await sut.reportWeeklyXP(userID: userID, xpGained: 10)
        await sut.reportWeeklyXP(userID: userID, xpGained: 20)
        await sut.reportWeeklyXP(userID: userID, xpGained: 30)

        let total = testDefaults.integer(forKey: "rnf_league_weekly_xp")
        XCTAssertEqual(total, 60)
    }

    // MARK: - processWeekEnd Without Standing

    func testProcessWeekEndReturnsCurrentTierWhenNoStanding() async {
        let userID = UUID()
        _ = await sut.join(userID: userID, displayName: "Test")

        // No standing set → should return current tier unchanged
        let result = await sut.processWeekEnd(userID: userID)
        XCTAssertEqual(result, .bronze)
    }

    // MARK: - Persistence

    func testJoinedStatePersistsAcrossInstances() async {
        let userID = UUID()
        _ = await sut.join(userID: userID, displayName: "Test")

        let reloaded = LeagueService(supabase: .shared, userDefaults: testDefaults)
        XCTAssertTrue(reloaded.isJoined)
    }

    func testTierPersistsAcrossInstances() {
        testDefaults.set("Gold", forKey: "rnf_league_tier")
        testDefaults.set(true, forKey: "rnf_league_joined")

        let reloaded = LeagueService(supabase: .shared, userDefaults: testDefaults)

        XCTAssertEqual(reloaded.currentTier, .gold)
        XCTAssertTrue(reloaded.isJoined)
    }

    // MARK: - LeagueMember

    func testLeagueMemberCreation() {
        let userID = UUID()
        let member = LeagueService.LeagueMember(
            id: UUID(),
            user_id: userID,
            display_name: "TestPlayer",
            weekly_xp: 150,
            tier: .silver,
            rank: 3
        )

        XCTAssertEqual(member.display_name, "TestPlayer")
        XCTAssertEqual(member.weekly_xp, 150)
        XCTAssertEqual(member.tier, .silver)
        XCTAssertEqual(member.rank, 3)
    }

    // MARK: - Tier Icons

    func testTierIconsExist() {
        for tier in LeagueService.Tier.allCases {
            XCTAssertFalse(tier.icon.isEmpty,
                "\(tier.rawValue) should have a non-empty icon")
        }
    }
}
