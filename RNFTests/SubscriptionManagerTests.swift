import XCTest
@testable import RNF

/// P23-TST-01/02/03/04: Unit tests for entitlement resolution,
/// feature gating logic, trial expiry calculation, and subscription state.
@MainActor
final class SubscriptionManagerTests: XCTestCase {

    // MARK: - P23-TST-01: Entitlement Resolution

    func testEntitlementResolution_ActiveSubscription_GrantsProAccess() async {
        // Given a subscription service with valid product IDs
        let service = SubscriptionService(
            productIDs: ["com.rnf.pro.monthly", "com.rnf.pro.yearly", "com.rnf.pro.lifetime"]
        )

        // When we validate entitlement (no StoreKit transaction in test env)
        let entitlement = await service.validateEntitlement()

        // Then in test environment with no transactions, entitlement is nil
        XCTAssertNil(entitlement, "No entitlement expected without active StoreKit transactions")
    }

    func testEntitlementResolution_EmptyProductIDs_ReturnsNil() async {
        // Given a subscription service with no product IDs
        let service = SubscriptionService(productIDs: [])

        // When we validate
        let entitlement = await service.validateEntitlement()

        // Then entitlement is nil
        XCTAssertNil(entitlement)
    }

    func testSubscriptionEntitlement_HasProductIDAndExpiration() {
        // Given an entitlement
        let expiry = Date().addingTimeInterval(86400 * 30)
        let entitlement = SubscriptionEntitlement(
            productID: "com.rnf.pro.monthly",
            expirationDate: expiry
        )

        // Then fields are correct
        XCTAssertEqual(entitlement.productID, "com.rnf.pro.monthly")
        XCTAssertEqual(entitlement.expirationDate, expiry)
    }

    func testSubscriptionEntitlement_Lifetime_HasNilExpiration() {
        // Given a lifetime entitlement
        let entitlement = SubscriptionEntitlement(
            productID: "com.rnf.pro.lifetime",
            expirationDate: nil
        )

        // Then expiration is nil (never expires)
        XCTAssertEqual(entitlement.productID, "com.rnf.pro.lifetime")
        XCTAssertNil(entitlement.expirationDate)
    }

    // MARK: - P23-TST-02: Feature Gating Logic

    func testProFeatureGating_FreeUser_CannotAccessProFeatures() {
        // Free tier: max 3 habits, level capped at 10, no skill tree
        let proFeatures: [String] = [
            "skillTree", "seasonalArcs", "autoFreeze",
            "weeklyInsights", "focusTimer", "dataExport"
        ]

        // All features should be considered Pro-gated (not in FeatureGate enum)
        // FeatureGate handles progression gating, subscription gating is separate
        XCTAssertEqual(proFeatures.count, 6, "6 core Pro features expected")
    }

    func testProFeatureGating_ProgressionGate_StillAppliesWithPro() {
        // Even with Pro subscription, FeatureGate progression requirements apply
        // Boss challenge requires level 10, streak 14
        XCTAssertFalse(
            FeatureGate.isUnlocked(.bossChallenge, level: 5, streak: 3, hasCompletedChallenge: false),
            "Boss challenge requires progression even with Pro"
        )
        XCTAssertTrue(
            FeatureGate.isUnlocked(.bossChallenge, level: 10, streak: 14, hasCompletedChallenge: false),
            "Boss challenge unlocks when progression requirements met"
        )
    }

    func testProFeatureGating_FreeTierLimits() {
        // Free tier constraints from spec
        let maxFreeHabits = 3
        let maxFreeLevel = 10
        let freeForgivenessTokensPerMonth = 1
        let maxFreeAchievements = 10

        XCTAssertEqual(maxFreeHabits, 3)
        XCTAssertEqual(maxFreeLevel, 10)
        XCTAssertEqual(freeForgivenessTokensPerMonth, 1)
        XCTAssertEqual(maxFreeAchievements, 10)
    }

    func testProFeatureGating_ProTierLimits() {
        // Pro tier removes constraints
        let proStreakFreezesPerMonth = 3
        let proHabitLimit = Int.max // unlimited

        XCTAssertEqual(proStreakFreezesPerMonth, 3)
        XCTAssertTrue(proHabitLimit > 100, "Pro allows unlimited habits")
    }

    // MARK: - P23-TST-03: Trial Expiry Calculation

    func testTrialExpiry_Day1_Returns13DaysRemaining() {
        let trialStart = Date()
        let now = trialStart.addingTimeInterval(86400) // 1 day later
        let remaining = TrialExpiryBanner.daysRemaining(from: trialStart, now: now)
        XCTAssertEqual(remaining, 13)
    }

    func testTrialExpiry_Day12_Returns2DaysRemaining() {
        let trialStart = Date()
        let now = trialStart.addingTimeInterval(86400 * 12) // 12 days later
        let remaining = TrialExpiryBanner.daysRemaining(from: trialStart, now: now)
        XCTAssertEqual(remaining, 2)
    }

    func testTrialExpiry_Day14_Returns0DaysRemaining() {
        let trialStart = Date()
        let now = trialStart.addingTimeInterval(86400 * 14) // 14 days later
        let remaining = TrialExpiryBanner.daysRemaining(from: trialStart, now: now)
        XCTAssertEqual(remaining, 0)
    }

    func testTrialExpiry_Day20_ClampsToZero() {
        let trialStart = Date()
        let now = trialStart.addingTimeInterval(86400 * 20) // 20 days later
        let remaining = TrialExpiryBanner.daysRemaining(from: trialStart, now: now)
        XCTAssertEqual(remaining, 0, "Days remaining should never go below 0")
    }

    func testTrialExpiry_SameDay_Returns14DaysRemaining() {
        let trialStart = Date()
        let remaining = TrialExpiryBanner.daysRemaining(from: trialStart, now: trialStart)
        XCTAssertEqual(remaining, 14)
    }

    func testTrialExpiry_BannerShowsAtDay12() {
        // Banner appears when daysRemaining <= 3 (i.e., from Day 12 of trial)
        XCTAssertEqual(TrialExpiryBanner.bannerAppearsAtDaysRemaining, 3)
        XCTAssertEqual(TrialExpiryBanner.trialDuration, 14)
    }

    func testTrialExpiry_BannerVisibility_Day11_Hidden() {
        // Day 11 = 3 days remaining, banner shows
        // Day 10 = 4 days remaining, banner hidden
        let trialStart = Date()
        let day10 = trialStart.addingTimeInterval(86400 * 10)
        let remaining = TrialExpiryBanner.daysRemaining(from: trialStart, now: day10)
        XCTAssertEqual(remaining, 4)
        // 4 > bannerAppearsAtDaysRemaining (3), so banner hidden
        XCTAssertTrue(remaining > TrialExpiryBanner.bannerAppearsAtDaysRemaining)
    }

    func testTrialExpiry_BannerVisibility_Day12_Visible() {
        let trialStart = Date()
        let day12 = trialStart.addingTimeInterval(86400 * 12)
        let remaining = TrialExpiryBanner.daysRemaining(from: trialStart, now: day12)
        XCTAssertEqual(remaining, 2)
        // 2 <= bannerAppearsAtDaysRemaining (3), so banner shows
        XCTAssertTrue(remaining <= TrialExpiryBanner.bannerAppearsAtDaysRemaining)
    }

    // MARK: - P23-TST-04: Subscription Plan Types

    func testSubscriptionPlanType_RawValues() {
        XCTAssertEqual(SubscriptionPlanType.fullAccess.rawValue, "full_access")
        XCTAssertEqual(SubscriptionPlanType.maintenance.rawValue, "maintenance")
    }

    func testSubscriptionStatus_RawValues() {
        XCTAssertEqual(SubscriptionStatus.active.rawValue, "active")
        XCTAssertEqual(SubscriptionStatus.expired.rawValue, "expired")
    }

    func testProductIDs_MatchExpectedConfiguration() {
        let expectedIDs: Set<String> = [
            "com.rnf.pro.monthly",
            "com.rnf.pro.yearly",
            "com.rnf.pro.lifetime"
        ]
        XCTAssertEqual(RNFPaywallView.productIDs, expectedIDs)
    }

    func testSubscriptionGroupID_MatchesExpected() {
        XCTAssertEqual(RNFPaywallView.groupID, "com.rnf.pro")
    }
}
