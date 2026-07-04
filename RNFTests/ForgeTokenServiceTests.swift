import XCTest
@testable import RNF

// P24-TST-02: ForgeTokenService Tests
// Validates earn/spend/balance, insufficient funds, and negative amount rejection

@MainActor
final class ForgeTokenServiceTests: XCTestCase {

    private var sut: ForgeTokenService!
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "ForgeTokenServiceTests")!
        testDefaults.removePersistentDomain(forName: "ForgeTokenServiceTests")
        sut = ForgeTokenService(supabase: .shared, userDefaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "ForgeTokenServiceTests")
        testDefaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialBalanceIsZero() {
        XCTAssertEqual(sut.balance, 0)
    }

    func testInitialTransactionsEmpty() {
        XCTAssertTrue(sut.transactions.isEmpty)
    }

    // MARK: - Earn Tokens

    func testEarnIncreasesBalance() {
        sut.earn(amount: 10, reason: "Test reward")
        XCTAssertEqual(sut.balance, 10)
    }

    func testEarnMultipleTimesAccumulates() {
        sut.earn(amount: 5, reason: "First")
        sut.earn(amount: 7, reason: "Second")
        sut.earn(amount: 3, reason: "Third")
        XCTAssertEqual(sut.balance, 15)
    }

    func testEarnCreatesTransaction() {
        sut.earn(amount: 10, reason: "Challenge completed")

        XCTAssertEqual(sut.transactions.count, 1)
        XCTAssertEqual(sut.transactions.first?.type, .earned)
        XCTAssertEqual(sut.transactions.first?.amount, 10)
        XCTAssertEqual(sut.transactions.first?.reason, "Challenge completed")
    }

    func testEarnZeroAmountIsIgnored() {
        sut.earn(amount: 0, reason: "Zero reward")
        XCTAssertEqual(sut.balance, 0)
        XCTAssertTrue(sut.transactions.isEmpty)
    }

    func testEarnNegativeAmountIsRejected() {
        sut.earn(amount: -5, reason: "Negative reward")
        XCTAssertEqual(sut.balance, 0)
        XCTAssertTrue(sut.transactions.isEmpty)
    }

    // MARK: - Spend Tokens

    func testSpendDecreasesBalance() {
        sut.earn(amount: 20, reason: "Setup")
        let result = sut.spend(amount: 8, reason: "Purchase")

        XCTAssertTrue(result)
        XCTAssertEqual(sut.balance, 12)
    }

    func testSpendExactBalanceReturnsTrue() {
        sut.earn(amount: 10, reason: "Setup")
        let result = sut.spend(amount: 10, reason: "Exact spend")

        XCTAssertTrue(result)
        XCTAssertEqual(sut.balance, 0)
    }

    func testSpendCreatesTransaction() {
        sut.earn(amount: 20, reason: "Setup")
        sut.spend(amount: 5, reason: "Streak freeze")

        let spendTx = sut.transactions.last
        XCTAssertEqual(spendTx?.type, .spent)
        XCTAssertEqual(spendTx?.amount, 5)
        XCTAssertEqual(spendTx?.reason, "Streak freeze")
    }

    // MARK: - Insufficient Funds

    func testSpendReturnsFalseWhenInsufficientFunds() {
        sut.earn(amount: 5, reason: "Setup")
        let result = sut.spend(amount: 10, reason: "Too expensive")

        XCTAssertFalse(result)
        XCTAssertEqual(sut.balance, 5, "Balance unchanged on insufficient funds")
    }

    func testSpendDoesNotCreateTransactionWhenInsufficient() {
        sut.earn(amount: 5, reason: "Setup")
        sut.spend(amount: 10, reason: "Too expensive")

        XCTAssertEqual(sut.transactions.count, 1)
        XCTAssertEqual(sut.transactions.first?.type, .earned)
    }

    func testSpendReturnsFalseWithZeroBalance() {
        let result = sut.spend(amount: 1, reason: "Nothing to spend")
        XCTAssertFalse(result)
        XCTAssertEqual(sut.balance, 0)
    }

    // MARK: - Negative Amounts Rejected

    func testSpendNegativeAmountReturnsFalse() {
        sut.earn(amount: 20, reason: "Setup")
        let result = sut.spend(amount: -5, reason: "Negative spend")

        XCTAssertFalse(result)
        XCTAssertEqual(sut.balance, 20, "Balance unchanged on negative spend")
    }

    func testSpendZeroAmountReturnsFalse() {
        sut.earn(amount: 10, reason: "Setup")
        let result = sut.spend(amount: 0, reason: "Zero spend")

        XCTAssertFalse(result)
        XCTAssertEqual(sut.balance, 10)
    }

    // MARK: - canAfford

    func testCanAffordReturnsTrueWhenSufficientBalance() {
        sut.earn(amount: 15, reason: "Setup")

        XCTAssertTrue(sut.canAfford(15))
        XCTAssertTrue(sut.canAfford(10))
        XCTAssertTrue(sut.canAfford(1))
    }

    func testCanAffordReturnsFalseWhenInsufficient() {
        sut.earn(amount: 5, reason: "Setup")

        XCTAssertFalse(sut.canAfford(6))
        XCTAssertFalse(sut.canAfford(100))
    }

    func testCanAffordReturnsTrueForZeroCost() {
        XCTAssertTrue(sut.canAfford(0))
    }

    // MARK: - Persistence

    func testBalancePersistsAcrossInstances() {
        sut.earn(amount: 25, reason: "Persist test")

        let newInstance = ForgeTokenService(supabase: .shared, userDefaults: testDefaults)
        XCTAssertEqual(newInstance.balance, 25)
    }

    func testTransactionsPersistAcrossInstances() {
        sut.earn(amount: 10, reason: "First")
        sut.earn(amount: 5, reason: "Second")
        sut.spend(amount: 3, reason: "Spend")

        let newInstance = ForgeTokenService(supabase: .shared, userDefaults: testDefaults)
        XCTAssertEqual(newInstance.transactions.count, 3)
    }

    // MARK: - Ledger Trimming

    func testLedgerTrimmedTo100Transactions() {
        for i in 0..<110 {
            sut.earn(amount: 1, reason: "Transaction \(i)")
        }

        let reloaded = ForgeTokenService(supabase: .shared, userDefaults: testDefaults)
        XCTAssertLessThanOrEqual(reloaded.transactions.count, 100)
        XCTAssertEqual(reloaded.balance, 110)
    }
}
