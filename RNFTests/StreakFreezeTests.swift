import XCTest
@testable import RNF

// P24-TST-03: Streak Freeze Tests
// Validates auto-apply on missed day, monthly allocation (3/month Pro),
// token purchase path (10 tokens = 1 freeze, max 2/month)

@MainActor
final class StreakFreezeTests: XCTestCase {

    private var forgeTokenService: ForgeTokenService!
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "StreakFreezeTests")!
        testDefaults.removePersistentDomain(forName: "StreakFreezeTests")
        forgeTokenService = ForgeTokenService(supabase: .shared, userDefaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "StreakFreezeTests")
        testDefaults = nil
        forgeTokenService = nil
        super.tearDown()
    }

    // MARK: - Streak Freeze Model

    /// Lightweight model matching spec: user has freezes_available, freezes_used_this_month
    struct StreakFreezeState {
        var freezesAvailable: Int = 0
        var freezesUsedThisMonth: Int = 0
        var tokenPurchasesThisMonth: Int = 0
        var isPro: Bool = false

        static let proMonthlyAllocation = 3
        static let tokenCostPerFreeze = 10
        static let maxTokenPurchasesPerMonth = 2

        mutating func allocateMonthlyFreezes() {
            freezesUsedThisMonth = 0
            tokenPurchasesThisMonth = 0
            if isPro {
                freezesAvailable += Self.proMonthlyAllocation
            }
        }

        enum FreezeResult {
            case applied
            case noFreezesAvailable
        }

        mutating func autoApplyOnMissedDay() -> FreezeResult {
            guard freezesAvailable > 0 else { return .noFreezesAvailable }
            freezesAvailable -= 1
            freezesUsedThisMonth += 1
            return .applied
        }

        enum PurchaseResult {
            case success
            case insufficientTokens
            case monthlyLimitReached
        }

        @MainActor
        mutating func purchaseFreezeWithTokens(forgeService: ForgeTokenService) -> PurchaseResult {
            guard tokenPurchasesThisMonth < Self.maxTokenPurchasesPerMonth else {
                return .monthlyLimitReached
            }
            guard forgeService.canAfford(Self.tokenCostPerFreeze) else {
                return .insufficientTokens
            }

            let spent = forgeService.spend(amount: Self.tokenCostPerFreeze, reason: "Streak freeze purchase")
            guard spent else { return .insufficientTokens }

            freezesAvailable += 1
            tokenPurchasesThisMonth += 1
            return .success
        }
    }

    // MARK: - Auto-Apply on Missed Day

    func testAutoApplyDecrementsFreezes() {
        var state = StreakFreezeState(freezesAvailable: 2)

        let result = state.autoApplyOnMissedDay()

        XCTAssertEqual(result, .applied)
        XCTAssertEqual(state.freezesAvailable, 1)
        XCTAssertEqual(state.freezesUsedThisMonth, 1)
    }

    func testAutoApplyFailsWhenNoFreezesAvailable() {
        var state = StreakFreezeState(freezesAvailable: 0)

        let result = state.autoApplyOnMissedDay()

        XCTAssertEqual(result, .noFreezesAvailable)
        XCTAssertEqual(state.freezesAvailable, 0)
    }

    func testAutoApplyUsesAllFreezesSequentially() {
        var state = StreakFreezeState(freezesAvailable: 3)

        XCTAssertEqual(state.autoApplyOnMissedDay(), .applied)
        XCTAssertEqual(state.autoApplyOnMissedDay(), .applied)
        XCTAssertEqual(state.autoApplyOnMissedDay(), .applied)
        XCTAssertEqual(state.autoApplyOnMissedDay(), .noFreezesAvailable)

        XCTAssertEqual(state.freezesAvailable, 0)
        XCTAssertEqual(state.freezesUsedThisMonth, 3)
    }

    // MARK: - Monthly Allocation (3/month Pro)

    func testProUserGets3FreezesOnMonthlyReset() {
        var state = StreakFreezeState(isPro: true)

        state.allocateMonthlyFreezes()

        XCTAssertEqual(state.freezesAvailable, 3)
    }

    func testFreeUserGetsNoFreezesOnMonthlyReset() {
        var state = StreakFreezeState(isPro: false)

        state.allocateMonthlyFreezes()

        XCTAssertEqual(state.freezesAvailable, 0)
    }

    func testMonthlyResetResetsUsageCounters() {
        var state = StreakFreezeState(
            freezesAvailable: 1,
            freezesUsedThisMonth: 2,
            tokenPurchasesThisMonth: 1,
            isPro: true
        )

        state.allocateMonthlyFreezes()

        XCTAssertEqual(state.freezesUsedThisMonth, 0)
        XCTAssertEqual(state.tokenPurchasesThisMonth, 0)
        // Existing 1 + 3 new = 4 available
        XCTAssertEqual(state.freezesAvailable, 4)
    }

    func testProAllocationAccumulatesWithExisting() {
        var state = StreakFreezeState(freezesAvailable: 2, isPro: true)

        state.allocateMonthlyFreezes()

        XCTAssertEqual(state.freezesAvailable, 5) // 2 existing + 3 new
    }

    // MARK: - Token Purchase Path (10 tokens = 1 freeze)

    func testPurchaseFreezeWith10Tokens() {
        forgeTokenService.earn(amount: 10, reason: "Setup")
        var state = StreakFreezeState()

        let result = state.purchaseFreezeWithTokens(forgeService: forgeTokenService)

        XCTAssertEqual(result, .success)
        XCTAssertEqual(state.freezesAvailable, 1)
        XCTAssertEqual(state.tokenPurchasesThisMonth, 1)
        XCTAssertEqual(forgeTokenService.balance, 0)
    }

    func testPurchaseFreezeFailsWithInsufficientTokens() {
        forgeTokenService.earn(amount: 9, reason: "Setup — not enough")
        var state = StreakFreezeState()

        let result = state.purchaseFreezeWithTokens(forgeService: forgeTokenService)

        XCTAssertEqual(result, .insufficientTokens)
        XCTAssertEqual(state.freezesAvailable, 0)
        XCTAssertEqual(forgeTokenService.balance, 9, "Tokens should not be spent")
    }

    func testPurchaseFreezeFailsWithZeroTokens() {
        var state = StreakFreezeState()

        let result = state.purchaseFreezeWithTokens(forgeService: forgeTokenService)

        XCTAssertEqual(result, .insufficientTokens)
        XCTAssertEqual(state.freezesAvailable, 0)
    }

    // MARK: - Max 2 Token Purchases Per Month

    func testMaxTwoTokenPurchasesPerMonth() {
        forgeTokenService.earn(amount: 30, reason: "Setup — plenty")
        var state = StreakFreezeState()

        let first = state.purchaseFreezeWithTokens(forgeService: forgeTokenService)
        let second = state.purchaseFreezeWithTokens(forgeService: forgeTokenService)
        let third = state.purchaseFreezeWithTokens(forgeService: forgeTokenService)

        XCTAssertEqual(first, .success)
        XCTAssertEqual(second, .success)
        XCTAssertEqual(third, .monthlyLimitReached)

        XCTAssertEqual(state.freezesAvailable, 2)
        XCTAssertEqual(state.tokenPurchasesThisMonth, 2)
        // Only 20 tokens spent (2 × 10)
        XCTAssertEqual(forgeTokenService.balance, 10)
    }

    func testMonthlyResetAllowsNewPurchases() {
        forgeTokenService.earn(amount: 30, reason: "Setup")
        var state = StreakFreezeState()

        // Use up monthly limit
        _ = state.purchaseFreezeWithTokens(forgeService: forgeTokenService)
        _ = state.purchaseFreezeWithTokens(forgeService: forgeTokenService)
        XCTAssertEqual(state.purchaseFreezeWithTokens(forgeService: forgeTokenService), .monthlyLimitReached)

        // Reset month
        state.allocateMonthlyFreezes()

        // Should be able to purchase again
        forgeTokenService.earn(amount: 10, reason: "New month tokens")
        let result = state.purchaseFreezeWithTokens(forgeService: forgeTokenService)
        XCTAssertEqual(result, .success)
    }

    // MARK: - Integration: Purchase + Auto-Apply

    func testPurchasedFreezeCanBeAutoApplied() {
        forgeTokenService.earn(amount: 10, reason: "Setup")
        var state = StreakFreezeState()

        _ = state.purchaseFreezeWithTokens(forgeService: forgeTokenService)
        XCTAssertEqual(state.freezesAvailable, 1)

        let applyResult = state.autoApplyOnMissedDay()
        XCTAssertEqual(applyResult, .applied)
        XCTAssertEqual(state.freezesAvailable, 0)
    }

    func testProFreezesAndPurchasedFreezesStackForAutoApply() {
        forgeTokenService.earn(amount: 20, reason: "Setup")
        var state = StreakFreezeState(isPro: true)

        state.allocateMonthlyFreezes() // +3
        _ = state.purchaseFreezeWithTokens(forgeService: forgeTokenService) // +1
        _ = state.purchaseFreezeWithTokens(forgeService: forgeTokenService) // +1

        XCTAssertEqual(state.freezesAvailable, 5) // 3 Pro + 2 purchased

        // Use them all
        for _ in 0..<5 {
            XCTAssertEqual(state.autoApplyOnMissedDay(), .applied)
        }
        XCTAssertEqual(state.autoApplyOnMissedDay(), .noFreezesAvailable)
        XCTAssertEqual(state.freezesAvailable, 0)
    }
}

// MARK: - Equatable conformance for test assertions

extension StreakFreezeTests.StreakFreezeState.FreezeResult: Equatable {}
extension StreakFreezeTests.StreakFreezeState.PurchaseResult: Equatable {}
