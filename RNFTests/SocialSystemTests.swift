import XCTest
@testable import RNF

final class SocialSystemTests: XCTestCase {

    // P17-TST-01: Guild model integrity
    func testGuildModelInitialization() {
        let userId = UUID()
        let guild = Guild(id: UUID(), name: "Iron Legion", description: "Discipline warriors", memberCount: 1, totalXP: 0, created_by: userId, created_at: nil)
        XCTAssertEqual(guild.name, "Iron Legion")
        XCTAssertEqual(guild.memberCount, 1)
        XCTAssertEqual(guild.created_by, userId)
    }

    func testGuildMemberRoles() {
        let member = GuildMember(id: UUID(), guild_id: UUID(), user_id: UUID(), role: .leader, joined_at: nil)
        XCTAssertEqual(member.role, .leader)
    }

    // P17-TST-02: Leaderboard ranking
    func testLeaderboardEntryRanking() {
        let entries = [
            LeaderboardEntry(id: UUID(), user_id: UUID(), username: "A", level: 10, xp_total: 5000, streak: 30, rank: 1),
            LeaderboardEntry(id: UUID(), user_id: UUID(), username: "B", level: 8, xp_total: 3000, streak: 20, rank: 2),
            LeaderboardEntry(id: UUID(), user_id: UUID(), username: "C", level: 5, xp_total: 1000, streak: 7, rank: 3),
        ]
        XCTAssertEqual(entries[0].rank, 1)
        XCTAssertTrue(entries[0].xp_total > entries[1].xp_total)
        XCTAssertTrue(entries[1].xp_total > entries[2].xp_total)
    }

    // P17-TST-03: Social challenge progress
    func testSocialChallengeProgress() {
        let challenge = SocialChallenge(
            id: UUID(), guild_id: UUID(), title: "100 Workouts", description: nil,
            target_completions: 100, current_completions: 50,
            status: .active, start_date: Date(), end_date: Date().addingDays(7), created_at: nil
        )
        XCTAssertEqual(challenge.progress, 0.5)
    }

    func testSocialChallengeProgressCapsAtOne() {
        let challenge = SocialChallenge(
            id: UUID(), guild_id: UUID(), title: "Test", description: nil,
            target_completions: 10, current_completions: 15,
            status: .completed, start_date: Date(), end_date: Date(), created_at: nil
        )
        XCTAssertEqual(challenge.progress, 1.0)
    }

    func testSocialChallengeStatusValues() {
        XCTAssertEqual(SocialChallenge.Status.active.rawValue, "active")
        XCTAssertEqual(SocialChallenge.Status.completed.rawValue, "completed")
        XCTAssertEqual(SocialChallenge.Status.expired.rawValue, "expired")
    }
}
