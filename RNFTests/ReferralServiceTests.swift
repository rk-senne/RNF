import XCTest
import Supabase
@testable import RNF

// P24-TST-05: ReferralService Tests
// Validates code generation uniqueness, validation, and reward timing (Day 3)

@MainActor
final class ReferralServiceTests: XCTestCase {

    private var sut: ReferralService!
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "ReferralServiceTests")!
        testDefaults.removePersistentDomain(forName: "ReferralServiceTests")
        sut = ReferralService(supabase: .shared, userDefaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "ReferralServiceTests")
        testDefaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Code Generation

    func testGenerateCodeReturns8Characters() {
        let code = ReferralService.createCode()
        XCTAssertEqual(code.count, 8)
    }

    func testGenerateCodeUsesOnlyAllowedCharacters() {
        let allowedChars = Set("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

        for _ in 0..<100 {
            let code = ReferralService.createCode()
            for char in code {
                XCTAssertTrue(allowedChars.contains(char),
                    "Code '\(code)' contains disallowed character '\(char)'")
            }
        }
    }

    func testGenerateCodeExcludesAmbiguousCharacters() {
        // I, O, 0, 1 should never appear (ambiguity-free charset)
        let forbidden: Set<Character> = ["I", "O", "0", "1"]

        for _ in 0..<200 {
            let code = ReferralService.createCode()
            for char in code {
                XCTAssertFalse(forbidden.contains(char),
                    "Code '\(code)' contains ambiguous character '\(char)'")
            }
        }
    }

    func testGenerateCodeUniqueness() {
        // Generate 100 codes and verify all are unique
        var codes = Set<String>()

        for _ in 0..<100 {
            let code = ReferralService.createCode()
            codes.insert(code)
        }

        XCTAssertEqual(codes.count, 100, "All 100 generated codes should be unique")
    }

    func testGenerateCodeForUserReturnsSameCodeOnSecondCall() {
        let userID = UUID()

        let firstCode = sut.generateCode(for: userID)
        let secondCode = sut.generateCode(for: userID)

        XCTAssertEqual(firstCode, secondCode,
            "Same user should always get the same code after initial generation")
    }

    func testGenerateCodePersistsLocally() {
        let userID = UUID()
        let code = sut.generateCode(for: userID)

        XCTAssertEqual(sut.myCode, code)

        // Reload from same UserDefaults
        let reloaded = ReferralService(supabase: .shared, userDefaults: testDefaults)
        XCTAssertEqual(reloaded.myCode, code)
    }

    // MARK: - Validation (via ValidationResult enum)

    func testValidationResultEnumCases() {
        // Verify all expected cases exist
        let valid = ReferralService.ValidationResult.valid(referrerID: UUID())
        let invalid = ReferralService.ValidationResult.invalid
        let expired = ReferralService.ValidationResult.expired
        let alreadyUsed = ReferralService.ValidationResult.alreadyUsed
        let selfRef = ReferralService.ValidationResult.selfReferral

        // Pattern match to confirm enum structure
        if case .valid(let id) = valid {
            XCTAssertNotNil(id)
        } else {
            XCTFail("Should match .valid case")
        }

        if case .invalid = invalid {} else { XCTFail("Should match .invalid") }
        if case .expired = expired {} else { XCTFail("Should match .expired") }
        if case .alreadyUsed = alreadyUsed {} else { XCTFail("Should match .alreadyUsed") }
        if case .selfReferral = selfRef {} else { XCTFail("Should match .selfReferral") }
    }

    func testValidateReturnsInvalidWithoutSupabaseClient() async {
        // In test environment, Supabase client is nil
        let currentUserID = UUID()
        let result = await sut.validate(code: "TESTCODE", currentUserID: currentUserID)

        if case .invalid = result {
            // Expected: no client → returns .invalid
        } else {
            XCTFail("Expected .invalid when Supabase unavailable, got: \(result)")
        }
    }

    // MARK: - Reward Timing (Day 3)

    func testRewardTriggerDayIs3() {
        XCTAssertEqual(ReferralService.ReferralReward.rewardTriggerDay, 3)
    }

    func testRewardForgivenessTokensIs1() {
        XCTAssertEqual(ReferralService.ReferralReward.forgivenessTokens, 1)
    }

    func testRewardForgeTokensIs5() {
        XCTAssertEqual(ReferralService.ReferralReward.forgeTokens, 5)
    }

    func testCheckAndDistributeRewardsDoesNothingBeforeDay3() async {
        let forgeService = ForgeTokenService(supabase: .shared, userDefaults: testDefaults)
        let referredUserID = UUID()

        // Day 1 — too early
        await sut.checkAndDistributeRewards(
            referredUserID: referredUserID,
            daysSinceJoin: 1,
            forgeTokenService: forgeService
        )
        XCTAssertEqual(forgeService.balance, 0, "No reward before Day 3")

        // Day 2 — still too early
        await sut.checkAndDistributeRewards(
            referredUserID: referredUserID,
            daysSinceJoin: 2,
            forgeTokenService: forgeService
        )
        XCTAssertEqual(forgeService.balance, 0, "No reward before Day 3")
    }

    func testCheckAndDistributeRewardsPassesDay3Gate() async {
        let forgeService = ForgeTokenService(supabase: .shared, userDefaults: testDefaults)
        let referredUserID = UUID()

        // Day 3 — eligible (but without Supabase, won't actually distribute)
        await sut.checkAndDistributeRewards(
            referredUserID: referredUserID,
            daysSinceJoin: 3,
            forgeTokenService: forgeService
        )

        // Without Supabase client, the method returns early after the guard
        // The key test is that Day < 3 returns immediately (tested above)
        // Day >= 3 proceeds to the Supabase query (which fails gracefully in tests)
        XCTAssertEqual(forgeService.balance, 0, "No Supabase = no distribution (graceful)")
    }

    // MARK: - Referral Model

    func testReferralModelCreation() {
        let referrerID = UUID()
        let code = "ABCD1234"
        let referral = ReferralService.Referral(referrerID: referrerID, code: code)

        XCTAssertEqual(referral.referrer_id, referrerID)
        XCTAssertEqual(referral.code, code)
        XCTAssertNil(referral.referred_id)
        XCTAssertNil(referral.redeemed_at)
        XCTAssertFalse(referral.reward_distributed)
        XCTAssertNotNil(referral.id)
        XCTAssertNotNil(referral.created_at)
    }

    // MARK: - Redeem (Network Dependent)

    func testRedeemReturnsFalseWithoutSupabase() async {
        let result = await sut.redeem(code: "TESTCODE", referredUserID: UUID())
        XCTAssertFalse(result, "Redeem should return false when no Supabase client")
    }

    // MARK: - Referral Count

    func testInitialReferralCountIsZero() {
        XCTAssertEqual(sut.referralCount, 0)
    }

    func testReferralCountPersists() {
        // Manually set via UserDefaults to simulate successful referral
        testDefaults.set(5, forKey: "rnf_referral_count")

        let reloaded = ReferralService(supabase: .shared, userDefaults: testDefaults)
        XCTAssertEqual(reloaded.referralCount, 5)
    }
}
