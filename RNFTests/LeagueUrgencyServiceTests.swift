import XCTest
@testable import RNF

@MainActor
final class LeagueUrgencyServiceTests: XCTestCase {

    // MARK: - Demotion Risk Assessment

    @MainActor
    func testDemotionRisk_topHalf_isSafe() {
        let service = LeagueUrgencyService(leagueService: LeagueService())
        let risk = service.assessDemotionRisk(
            currentRank: 5,
            totalMembers: 30,
            currentTier: .silver
        )
        XCTAssertEqual(risk, .safe)
    }

    @MainActor
    func testDemotionRisk_bottomZone_isAtRisk() {
        let service = LeagueUrgencyService(leagueService: LeagueService())
        let risk = service.assessDemotionRisk(
            currentRank: 26,  // 30 - 5 + 1 = 26 is demotion line
            totalMembers: 30,
            currentTier: .silver
        )
        XCTAssertEqual(risk, .atRisk(spotsFromSafety: 1))
    }

    @MainActor
    func testDemotionRisk_lastPlace_isDemotionLikely() {
        let service = LeagueUrgencyService(leagueService: LeagueService())
        let risk = service.assessDemotionRisk(
            currentRank: 29,  // second to last (0-indexed last)
            totalMembers: 30,
            currentTier: .gold
        )
        XCTAssertEqual(risk, .demotionLikely)
    }

    @MainActor
    func testDemotionRisk_lowestTier_alwaysSafe() {
        // Can't be demoted from Bronze
        let service = LeagueUrgencyService(leagueService: LeagueService())
        let risk = service.assessDemotionRisk(
            currentRank: 30,
            totalMembers: 30,
            currentTier: .bronze
        )
        XCTAssertEqual(risk, .safe)
    }

    // MARK: - Notification Timing

    @MainActor
    func testShouldNotify_thursday_returnsTrue() {
        let service = LeagueUrgencyService(leagueService: LeagueService())
        // Create a date that's Thursday
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 30 // Thursday July 30, 2026
        let thursday = Calendar.current.date(from: components)!
        XCTAssertTrue(service.shouldSendUrgencyNotification(today: thursday))
    }

    @MainActor
    func testShouldNotify_monday_returnsFalse() {
        let service = LeagueUrgencyService(leagueService: LeagueService())
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 27 // Monday
        let monday = Calendar.current.date(from: components)!
        XCTAssertFalse(service.shouldSendUrgencyNotification(today: monday))
    }

    // MARK: - Notification Generation

    @MainActor
    func testGenerateNotification_safe_returnsNil() {
        let service = LeagueUrgencyService(leagueService: LeagueService())
        let notification = service.generateUrgencyNotification(
            currentRank: 3,
            totalMembers: 30,
            currentTier: .silver
        )
        XCTAssertNil(notification)
    }

    @MainActor
    func testGenerateNotification_atRisk_returnsContent() {
        let service = LeagueUrgencyService(leagueService: LeagueService())
        let notification = service.generateUrgencyNotification(
            currentRank: 27,
            totalMembers: 30,
            currentTier: .gold
        )
        XCTAssertNotNil(notification)
        XCTAssertTrue(notification!.title.contains("Gold"))
    }

    // MARK: - Week Recap

    @MainActor
    func testWeekRecap_promoted_showsCelebration() {
        let service = LeagueUrgencyService(leagueService: LeagueService())
        let recap = service.generateWeekRecap(
            finalRank: 3,
            totalMembers: 30,
            tierName: "Silver",
            promoted: true,
            demoted: false,
            weeklyXP: 450
        )
        XCTAssertTrue(recap.promoted)
        XCTAssertFalse(recap.demoted)
        XCTAssertTrue(recap.summaryMessage.contains("Promoted"))
    }

    @MainActor
    func testWeekRecap_demoted_showsResult() {
        let service = LeagueUrgencyService(leagueService: LeagueService())
        let recap = service.generateWeekRecap(
            finalRank: 28,
            totalMembers: 30,
            tierName: "Silver",
            promoted: false,
            demoted: true,
            weeklyXP: 80
        )
        XCTAssertTrue(recap.demoted)
        XCTAssertTrue(recap.summaryMessage.contains("lower league"))
    }

    @MainActor
    func testWeekRecap_stayed_showsPosition() {
        let service = LeagueUrgencyService(leagueService: LeagueService())
        let recap = service.generateWeekRecap(
            finalRank: 12,
            totalMembers: 30,
            tierName: "Bronze",
            promoted: false,
            demoted: false,
            weeklyXP: 200
        )
        XCTAssertFalse(recap.promoted)
        XCTAssertFalse(recap.demoted)
        XCTAssertTrue(recap.summaryMessage.contains("#12"))
        XCTAssertTrue(recap.summaryMessage.contains("200 XP"))
    }

    // MARK: - Urgency Messages

    @MainActor
    func testUrgencyMessage_safe_noNotification() {
        let risk = LeagueUrgencyService.DemotionRisk.safe
        XCTAssertFalse(risk.shouldNotify)
    }

    @MainActor
    func testUrgencyMessage_atRisk_shouldNotify() {
        let risk = LeagueUrgencyService.DemotionRisk.atRisk(spotsFromSafety: 2)
        XCTAssertTrue(risk.shouldNotify)
        XCTAssertTrue(risk.urgencyMessage.contains("2 spots"))
    }

    @MainActor
    func testUrgencyMessage_demotionLikely_shouldNotify() {
        let risk = LeagueUrgencyService.DemotionRisk.demotionLikely
        XCTAssertTrue(risk.shouldNotify)
    }
}
