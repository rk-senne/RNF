import XCTest
@testable import RNF

@MainActor
final class GuestSessionManagerTests: XCTestCase {

    private var testDefaults: UserDefaults!
    private var sut: GuestSessionManager!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "GuestSessionManagerTests")!
        testDefaults.removePersistentDomain(forName: "GuestSessionManagerTests")
        sut = GuestSessionManager(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "GuestSessionManagerTests")
        testDefaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Session Lifecycle

    func testStartSessionSetsActiveState() {
        sut.startSession()

        XCTAssertTrue(sut.isSessionActive)
        XCTAssertFalse(sut.isSessionExpired)
        XCTAssertEqual(sut.guestXP, 0)
        XCTAssertTrue(sut.completedHabitIDs.isEmpty)
    }

    func testEndSessionClearsAllState() {
        sut.startSession()
        sut.completeHabit(id: "habit_1", xpReward: 15)

        sut.endSession()

        XCTAssertFalse(sut.isSessionActive)
        XCTAssertFalse(sut.isSessionExpired)
        XCTAssertEqual(sut.guestXP, 0)
        XCTAssertTrue(sut.completedHabitIDs.isEmpty)
    }

    // MARK: - TTL Expiry (P22-TST-01)

    func testSessionNotExpiredWithinTTL() {
        let futureExpiry = Date().addingTimeInterval(3 * 24 * 60 * 60)
        testDefaults.set(futureExpiry.timeIntervalSince1970, forKey: "rnf_guest_session_expiry")
        testDefaults.set(true, forKey: "rnf_guest_session_active")

        let manager = GuestSessionManager(defaults: testDefaults)

        XCTAssertTrue(manager.isSessionActive)
        XCTAssertFalse(manager.isSessionExpired)
    }

    func testSessionExpiredAfterTTL() {
        let pastExpiry = Date().addingTimeInterval(-1)
        testDefaults.set(pastExpiry.timeIntervalSince1970, forKey: "rnf_guest_session_expiry")
        testDefaults.set(true, forKey: "rnf_guest_session_active")

        let manager = GuestSessionManager(defaults: testDefaults)

        XCTAssertTrue(manager.isSessionActive)
        XCTAssertTrue(manager.isSessionExpired)
    }

    func testSessionExpiredWhenExpiryDateInPast() {
        let expiredDate = Date().addingTimeInterval(-2 * 24 * 60 * 60)
        testDefaults.set(expiredDate.timeIntervalSince1970, forKey: "rnf_guest_session_expiry")
        testDefaults.set(true, forKey: "rnf_guest_session_active")

        let manager = GuestSessionManager(defaults: testDefaults)

        XCTAssertTrue(manager.isSessionExpired)
    }

    func testSessionNotExpiredWhenExpiryInFuture() {
        let futureDate = Date().addingTimeInterval(1 * 24 * 60 * 60)
        testDefaults.set(futureDate.timeIntervalSince1970, forKey: "rnf_guest_session_expiry")
        testDefaults.set(true, forKey: "rnf_guest_session_active")

        let manager = GuestSessionManager(defaults: testDefaults)

        XCTAssertFalse(manager.isSessionExpired)
    }

    // MARK: - Habit Completion

    func testCompleteHabitAddsXPAndRecordsHabit() {
        sut.startSession()

        sut.completeHabit(id: "cold_shower", xpReward: 15)

        XCTAssertEqual(sut.guestXP, 15)
        XCTAssertTrue(sut.completedHabitIDs.contains("cold_shower"))
    }

    func testCompleteHabitIgnoresDuplicates() {
        sut.startSession()

        sut.completeHabit(id: "meditate", xpReward: 15)
        sut.completeHabit(id: "meditate", xpReward: 15)

        XCTAssertEqual(sut.guestXP, 15)
        XCTAssertEqual(sut.completedHabitIDs.count, 1)
    }

    func testCompleteHabitDoesNothingWhenExpired() {
        let pastExpiry = Date().addingTimeInterval(-1)
        testDefaults.set(pastExpiry.timeIntervalSince1970, forKey: "rnf_guest_session_expiry")
        testDefaults.set(true, forKey: "rnf_guest_session_active")

        let manager = GuestSessionManager(defaults: testDefaults)
        manager.completeHabit(id: "habit_1", xpReward: 15)

        XCTAssertEqual(manager.guestXP, 0)
        XCTAssertTrue(manager.completedHabitIDs.isEmpty)
    }

    func testCompleteHabitDoesNothingWhenInactive() {
        sut.completeHabit(id: "habit_1", xpReward: 15)
        XCTAssertEqual(sut.guestXP, 0)
    }

    // MARK: - Data Migration (P22-TST-01)

    func testSessionDataReturnsAccumulatedProgress() {
        sut.startSession()
        sut.completeHabit(id: "cold_shower", xpReward: 15)
        sut.completeHabit(id: "meditate", xpReward: 15)
        sut.completeHabit(id: "gratitude", xpReward: 15)

        let data = sut.sessionData

        XCTAssertNotNil(data)
        XCTAssertEqual(data?.xp, 45)
        XCTAssertEqual(data?.completedHabitIDs.count, 3)
        XCTAssertTrue(data?.completedHabitIDs.contains("cold_shower") ?? false)
        XCTAssertTrue(data?.completedHabitIDs.contains("meditate") ?? false)
        XCTAssertTrue(data?.completedHabitIDs.contains("gratitude") ?? false)
    }

    func testSessionDataReturnsNilWhenInactive() {
        XCTAssertNil(sut.sessionData)
    }

    func testGuestXPTransfersViaMigrationData() {
        sut.startSession()
        sut.completeHabit(id: "habit_a", xpReward: 20)
        sut.completeHabit(id: "habit_b", xpReward: 30)

        let migrationData = sut.sessionData

        XCTAssertEqual(migrationData?.xp, 50)
        XCTAssertEqual(migrationData?.completedHabitIDs, Set(["habit_a", "habit_b"]))
    }

    func testEndSessionClearsDataAfterMigration() {
        sut.startSession()
        sut.completeHabit(id: "habit_1", xpReward: 15)

        _ = sut.sessionData
        sut.endSession()

        XCTAssertNil(sut.sessionData)
        XCTAssertEqual(sut.guestXP, 0)
        XCTAssertTrue(sut.completedHabitIDs.isEmpty)
    }

    // MARK: - Persistence

    func testSessionPersistsAcrossInstances() {
        sut.startSession()
        sut.completeHabit(id: "persist_test", xpReward: 25)

        let newManager = GuestSessionManager(defaults: testDefaults)

        XCTAssertTrue(newManager.isSessionActive)
        XCTAssertEqual(newManager.guestXP, 25)
        XCTAssertTrue(newManager.completedHabitIDs.contains("persist_test"))
    }

    func testMultipleHabitsAccumulateXP() {
        sut.startSession()

        sut.completeHabit(id: "h1", xpReward: 10)
        sut.completeHabit(id: "h2", xpReward: 20)
        sut.completeHabit(id: "h3", xpReward: 30)

        XCTAssertEqual(sut.guestXP, 60)
        XCTAssertEqual(sut.completedHabitIDs.count, 3)
    }
}
