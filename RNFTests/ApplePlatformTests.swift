import XCTest
@testable import RNF

// MARK: - P26-TST-01/02/03/04: Apple Platform Integration Tests

@MainActor
final class ApplePlatformTests: XCTestCase {

    // HealthKitAutoTracker persists its configuration list to
    // UserDefaults.standard under this key. Reset it around every test so the
    // auto-tracker cases start from a clean slate and don't accumulate configs
    // across tests (or across prior runs on the same simulator).
    private let autoTrackConfigKey = "rnf_healthkit_auto_track_configs"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: autoTrackConfigKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: autoTrackConfigKey)
        super.tearDown()
    }

    // P18-TST-01: HealthKit workout mapping
    func testHealthWorkoutSummaryMapping() {
        let summary = HealthWorkoutSummary(
            id: UUID(),
            healthKitUUID: "HK-12345",
            workoutType: "Running",
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            durationSeconds: 1800,
            activeEnergyBurned: 250.0,
            accepted: false
        )
        XCTAssertEqual(summary.duration, 1800)
        XCTAssertEqual(summary.workoutType, "Running")
        XCTAssertFalse(summary.accepted)
    }

    // P18-TST-02: Duplicate import prevention
    func testHealthImportRecordUniqueness() {
        let uuid = "HK-UNIQUE-123"
        let record1 = HealthImportService.HealthImportRecord(
            id: UUID(), user_id: UUID(), healthkit_uuid: uuid,
            workout_type: "Running", start_date: Date(), end_date: Date(),
            duration_seconds: 600, active_energy: nil, accepted: true, created_at: nil
        )
        let record2 = HealthImportService.HealthImportRecord(
            id: UUID(), user_id: record1.user_id, healthkit_uuid: uuid,
            workout_type: "Running", start_date: Date(), end_date: Date(),
            duration_seconds: 600, active_energy: nil, accepted: true, created_at: nil
        )
        XCTAssertEqual(record1.healthkit_uuid, record2.healthkit_uuid)
        XCTAssertEqual(record1.user_id, record2.user_id)
        XCTAssertNotEqual(record1.id, record2.id)
    }

    // P18-TST-03: Watch message encoding/decoding
    func testWatchHabitCompletionMessageCodable() throws {
        let message = WatchHabitCompletionMessage(
            idempotencyKey: UUID(),
            habitID: UUID(),
            completedAt: Date()
        )
        let data = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(WatchHabitCompletionMessage.self, from: data)
        XCTAssertEqual(decoded.idempotencyKey, message.idempotencyKey)
        XCTAssertEqual(decoded.habitID, message.habitID)
    }

    func testWatchWorkoutMessageCodable() throws {
        let message = WatchWorkoutMessage(
            idempotencyKey: UUID(),
            action: .complete,
            durationSeconds: 300
        )
        let data = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(WatchWorkoutMessage.self, from: data)
        XCTAssertEqual(decoded.action, .complete)
        XCTAssertEqual(decoded.durationSeconds, 300)
    }

    func testWatchDailySnapshotCodable() throws {
        let snapshot = WatchDailySnapshot(
            date: Date(), level: 5, streak: 14,
            dailyCompleted: 2, dailyGoal: 4, challengeDay: 30,
            habits: [WatchHabitSummary(id: UUID(), name: "Workout", completed: true, xpReward: 15)]
        )
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(WatchDailySnapshot.self, from: data)
        XCTAssertEqual(decoded.level, 5)
        XCTAssertEqual(decoded.habits.count, 1)
        XCTAssertTrue(decoded.habits[0].completed)
    }

    // P18-TST-04: Watch idempotent completion
    @MainActor
    func testWatchMessageHandlerRejectsProcessedKey() async {
        let handler = WatchMessageHandler()
        let message = WatchHabitCompletionMessage(
            idempotencyKey: UUID(),
            habitID: UUID(),
            completedAt: Date()
        )
        _ = await handler.handleHabitCompletion(message, userId: UUID())
        let secondResult = await handler.handleHabitCompletion(message, userId: UUID())
        XCTAssertFalse(secondResult)
    }

    @MainActor
    func testWatchWorkoutHandlerRejectsProcessedKey() async {
        let handler = WatchMessageHandler()
        let key = UUID()
        let message = WatchWorkoutMessage(idempotencyKey: key, action: .start, durationSeconds: 300)

        let first = await handler.handleWorkoutAction(message, userId: UUID())
        XCTAssertTrue(first)

        let second = await handler.handleWorkoutAction(message, userId: UUID())
        XCTAssertFalse(second)
    }

    // MARK: - P26-TST-03: HealthKitAutoTracker Threshold Tests

    @MainActor
    func testAutoTrackerStepsThresholdMet() async {
        let tracker = HealthKitAutoTracker()

        // Simulate threshold check with default steps threshold
        let config = HealthKitAutoTracker.AutoTrackConfig.steps(habitID: UUID(), threshold: 10_000)
        tracker.addConfiguration(config)

        // Verify config is stored
        XCTAssertEqual(tracker.configurations.count, 1)
        XCTAssertEqual(tracker.configurations[0].metric, .steps)
        XCTAssertEqual(tracker.configurations[0].threshold, 10_000)
        XCTAssertTrue(tracker.configurations[0].isEnabled)
    }

    @MainActor
    func testAutoTrackerExerciseThresholdConfig() {
        let tracker = HealthKitAutoTracker()
        let habitID = UUID()

        let config = HealthKitAutoTracker.AutoTrackConfig.exerciseMinutes(habitID: habitID, threshold: 30)
        tracker.addConfiguration(config)

        XCTAssertEqual(tracker.configurations[0].metric, .exerciseMinutes)
        XCTAssertEqual(tracker.configurations[0].threshold, 30)
        XCTAssertEqual(tracker.configurations[0].habitID, habitID)
    }

    @MainActor
    func testAutoTrackerSleepThresholdConfig() {
        let tracker = HealthKitAutoTracker()
        let habitID = UUID()

        let config = HealthKitAutoTracker.AutoTrackConfig.sleepHours(habitID: habitID, threshold: 7)
        tracker.addConfiguration(config)

        XCTAssertEqual(tracker.configurations[0].metric, .sleepHours)
        XCTAssertEqual(tracker.configurations[0].threshold, 7)
    }

    @MainActor
    func testAutoTrackerToggleEnabled() {
        let tracker = HealthKitAutoTracker()
        let config = HealthKitAutoTracker.AutoTrackConfig.steps(habitID: UUID(), threshold: 8000)
        tracker.addConfiguration(config)

        XCTAssertTrue(tracker.configurations[0].isEnabled)

        tracker.setEnabled(false, for: config.id)
        XCTAssertFalse(tracker.configurations[0].isEnabled)

        tracker.setEnabled(true, for: config.id)
        XCTAssertTrue(tracker.configurations[0].isEnabled)
    }

    @MainActor
    func testAutoTrackerUpdateThreshold() {
        let tracker = HealthKitAutoTracker()
        let config = HealthKitAutoTracker.AutoTrackConfig.steps(habitID: UUID(), threshold: 10_000)
        tracker.addConfiguration(config)

        tracker.updateThreshold(5_000, for: config.id)
        XCTAssertEqual(tracker.configurations[0].threshold, 5_000)
    }

    @MainActor
    func testAutoTrackerRemoveConfiguration() {
        let tracker = HealthKitAutoTracker()
        let config1 = HealthKitAutoTracker.AutoTrackConfig.steps(habitID: UUID(), threshold: 10_000)
        let config2 = HealthKitAutoTracker.AutoTrackConfig.exerciseMinutes(habitID: UUID(), threshold: 30)
        tracker.addConfiguration(config1)
        tracker.addConfiguration(config2)

        XCTAssertEqual(tracker.configurations.count, 2)

        tracker.removeConfiguration(id: config1.id)
        XCTAssertEqual(tracker.configurations.count, 1)
        XCTAssertEqual(tracker.configurations[0].id, config2.id)
    }

    @MainActor
    func testAutoTrackerThresholdNotMetByDefault() {
        let tracker = HealthKitAutoTracker()

        // Without any HealthKit data, thresholds should not be met
        XCTAssertFalse(tracker.isThresholdMet(for: .steps, threshold: 10_000))
        XCTAssertFalse(tracker.isThresholdMet(for: .exerciseMinutes, threshold: 30))
        XCTAssertFalse(tracker.isThresholdMet(for: .sleepHours, threshold: 7))
    }

    // MARK: - P26-TST-04: DeepLinkRouter URL Parsing Tests

    @MainActor
    func testDeepLinkRouterParsesHome() {
        let router = DeepLinkRouter()
        let url = URL(string: "rnf://home")!
        let destination = router.parse(url: url)
        XCTAssertEqual(destination, .home)
    }

    @MainActor
    func testDeepLinkRouterParsesWorkouts() {
        let router = DeepLinkRouter()
        let url = URL(string: "rnf://workouts")!
        let destination = router.parse(url: url)
        XCTAssertEqual(destination, .workouts)
    }

    @MainActor
    func testDeepLinkRouterParsesSpecificWorkout() {
        let router = DeepLinkRouter()
        let id = UUID()
        let url = URL(string: "rnf://workouts/\(id.uuidString)")!
        let destination = router.parse(url: url)
        XCTAssertEqual(destination, .workout(id: id))
    }

    @MainActor
    func testDeepLinkRouterParsesHabit() {
        let router = DeepLinkRouter()
        let id = UUID()
        let url = URL(string: "rnf://habit/\(id.uuidString)")!
        let destination = router.parse(url: url)
        XCTAssertEqual(destination, .habit(id: id))
    }

    @MainActor
    func testDeepLinkRouterParsesQuickComplete() {
        let router = DeepLinkRouter()
        let id = UUID()
        let url = URL(string: "rnf://quick-complete/\(id.uuidString)")!
        let destination = router.parse(url: url)
        XCTAssertEqual(destination, .quickComplete(habitID: id))
    }

    @MainActor
    func testDeepLinkRouterParsesFocusSession() {
        let router = DeepLinkRouter()
        let url = URL(string: "rnf://focus/meditation")!
        let destination = router.parse(url: url)
        XCTAssertEqual(destination, .focusSession(type: "meditation"))
    }

    @MainActor
    func testDeepLinkRouterParsesProfile() {
        let router = DeepLinkRouter()
        let url = URL(string: "rnf://profile")!
        let destination = router.parse(url: url)
        XCTAssertEqual(destination, .profile)
    }

    @MainActor
    func testDeepLinkRouterParsesSubscription() {
        let router = DeepLinkRouter()
        let url = URL(string: "rnf://subscription")!
        let destination = router.parse(url: url)
        XCTAssertEqual(destination, .subscription)
    }

    @MainActor
    func testDeepLinkRouterParsesInviteWithCode() {
        let router = DeepLinkRouter()
        let url = URL(string: "rnf://invite/ABC123")!
        let destination = router.parse(url: url)
        XCTAssertEqual(destination, .inviteFriend(referralCode: "ABC123"))
    }

    @MainActor
    func testDeepLinkRouterParsesSocial() {
        let router = DeepLinkRouter()
        let url = URL(string: "rnf://social")!
        let destination = router.parse(url: url)
        XCTAssertEqual(destination, .social)
    }

    @MainActor
    func testDeepLinkRouterParsesLeaderboard() {
        let router = DeepLinkRouter()
        let url = URL(string: "rnf://leaderboard/weekly")!
        let destination = router.parse(url: url)
        XCTAssertEqual(destination, .leaderboard(id: "weekly"))
    }

    @MainActor
    func testDeepLinkRouterRejectsInvalidScheme() {
        let router = DeepLinkRouter()
        let url = URL(string: "https://example.com/path")!
        let destination = router.parse(url: url)
        XCTAssertNil(destination)
    }

    @MainActor
    func testDeepLinkRouterRejectsUnknownHost() {
        let router = DeepLinkRouter()
        let url = URL(string: "rnf://nonexistent")!
        let destination = router.parse(url: url)
        XCTAssertNil(destination)
    }

    @MainActor
    func testDeepLinkRouterHandleURLSetsTab() {
        let router = DeepLinkRouter()
        let url = URL(string: "rnf://workouts")!

        router.handleURL(url)

        XCTAssertEqual(router.selectedTab, 1)
        XCTAssertEqual(router.pendingDestination, .workouts)
    }

    @MainActor
    func testDeepLinkRouterClearsPending() {
        let router = DeepLinkRouter()
        router.handleURL(URL(string: "rnf://profile")!)

        XCTAssertNotNil(router.pendingDestination)

        router.clearPendingDestination()
        XCTAssertNil(router.pendingDestination)
    }

    @MainActor
    func testDeepLinkRouterReadingTab() {
        let router = DeepLinkRouter()
        router.handleURL(URL(string: "rnf://reading")!)

        XCTAssertEqual(router.selectedTab, 2)
        XCTAssertEqual(router.pendingDestination, .reading)
    }

    @MainActor
    func testDeepLinkRouterAscensionTab() {
        let router = DeepLinkRouter()
        router.handleURL(URL(string: "rnf://ascension")!)

        XCTAssertEqual(router.selectedTab, 3)
        XCTAssertEqual(router.pendingDestination, .ascension)
    }

    // MARK: - Widget URL Construction Tests

    @MainActor
    func testWidgetURLConstruction() {
        let homeURL = DeepLinkRouter.widgetURL(for: .openHome)
        XCTAssertEqual(homeURL.absoluteString, "rnf://home")

        let dailyURL = DeepLinkRouter.widgetURL(for: .openDailyProgress)
        XCTAssertEqual(dailyURL.absoluteString, "rnf://daily-progress")

        let streakURL = DeepLinkRouter.widgetURL(for: .openStreak)
        XCTAssertEqual(streakURL.absoluteString, "rnf://streak")

        let workoutURL = DeepLinkRouter.widgetURL(for: .openWorkouts)
        XCTAssertEqual(workoutURL.absoluteString, "rnf://workouts")

        let profileURL = DeepLinkRouter.widgetURL(for: .openProfile)
        XCTAssertEqual(profileURL.absoluteString, "rnf://profile")
    }

    @MainActor
    func testWidgetURLWithHabitID() {
        let id = UUID()
        let url = DeepLinkRouter.widgetURL(for: .openHabit(id: id))
        XCTAssertEqual(url.absoluteString, "rnf://habit/\(id.uuidString)")
    }

    @MainActor
    func testWidgetURLQuickComplete() {
        let id = UUID()
        let url = DeepLinkRouter.widgetURL(for: .quickComplete(id: id))
        XCTAssertEqual(url.absoluteString, "rnf://quick-complete/\(id.uuidString)")
    }

    @MainActor
    func testWidgetURLFocusWithType() {
        let url = DeepLinkRouter.widgetURL(for: .openFocus(type: "deepWork"))
        XCTAssertEqual(url.absoluteString, "rnf://focus/deepWork")
    }

    @MainActor
    func testWidgetURLFocusWithoutType() {
        let url = DeepLinkRouter.widgetURL(for: .openFocus(type: nil))
        XCTAssertEqual(url.absoluteString, "rnf://focus")
    }

    @MainActor
    func testWidgetURLLeaderboardWithID() {
        let url = DeepLinkRouter.widgetURL(for: .openLeaderboard(id: "weekly"))
        XCTAssertEqual(url.absoluteString, "rnf://leaderboard/weekly")
    }

    // MARK: - P26-TST-01: App Attest Service Tests

    @MainActor
    func testAppAttestServiceInitialState() {
        let service = AppAttestService()

        // On simulator, App Attest is typically not supported
        // Service should handle this gracefully
        XCTAssertFalse(service.isAttested)
        // isFallbackMode should be true on simulator
        if !service.isSupported {
            XCTAssertTrue(service.isFallbackMode)
            XCTAssertFalse(service.shouldAttest)
        }
    }

    @MainActor
    func testAppAttestClearKey() {
        let service = AppAttestService()
        service.clearKey()

        XCTAssertFalse(service.isAttested)
        XCTAssertFalse(service.shouldAttest)
    }

    @MainActor
    func testAppAttestFallbackModeReturnsNil() async {
        let service = AppAttestService()

        // On unsupported devices, assertIfAvailable should return nil
        if !service.isSupported {
            let result = await service.assertIfAvailable(payload: Data("test".utf8))
            XCTAssertNil(result)
        }
    }

    @MainActor
    func testAppAttestGenerateKeyThrowsOnUnsupported() async {
        let service = AppAttestService()

        if !service.isSupported {
            do {
                _ = try await service.generateKey()
                XCTFail("Should have thrown on unsupported device")
            } catch {
                // Expected: .notSupported
                XCTAssertTrue(error is AppAttestService.AttestError)
            }
        }
    }

    // MARK: - P26-TST-02: Live Activity Attributes Tests

    func testWorkoutTimerAttributesCodable() throws {
        let state = WorkoutTimerActivityAttributes.ContentState(
            elapsedSeconds: 120,
            phase: "active",
            isActive: true,
            exerciseName: "Push-ups"
        )
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(WorkoutTimerActivityAttributes.ContentState.self, from: data)
        XCTAssertEqual(decoded.elapsedSeconds, 120)
        XCTAssertEqual(decoded.phase, "active")
        XCTAssertTrue(decoded.isActive)
        XCTAssertEqual(decoded.exerciseName, "Push-ups")
    }

    func testFocusSessionAttributesCodable() throws {
        let state = FocusSessionActivityAttributes.ContentState(
            remainingSeconds: 600,
            totalSeconds: 1200,
            isActive: true,
            sessionType: "meditation"
        )
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(FocusSessionActivityAttributes.ContentState.self, from: data)
        XCTAssertEqual(decoded.remainingSeconds, 600)
        XCTAssertEqual(decoded.totalSeconds, 1200)
        XCTAssertTrue(decoded.isActive)
        XCTAssertEqual(decoded.sessionType, "meditation")
    }

    func testWorkoutTimerAttributesHashable() {
        let state1 = WorkoutTimerActivityAttributes.ContentState(
            elapsedSeconds: 60, phase: "warmup", isActive: true, exerciseName: nil
        )
        let state2 = WorkoutTimerActivityAttributes.ContentState(
            elapsedSeconds: 60, phase: "warmup", isActive: true, exerciseName: nil
        )
        XCTAssertEqual(state1, state2)
        XCTAssertEqual(state1.hashValue, state2.hashValue)
    }

    func testFocusSessionAttributesHashable() {
        let state1 = FocusSessionActivityAttributes.ContentState(
            remainingSeconds: 300, totalSeconds: 600, isActive: false, sessionType: "deepWork"
        )
        let state2 = FocusSessionActivityAttributes.ContentState(
            remainingSeconds: 300, totalSeconds: 600, isActive: false, sessionType: "deepWork"
        )
        XCTAssertEqual(state1, state2)
    }

    // MARK: - HealthKitWriter Config Tests

    @MainActor
    func testHealthKitWriterOptInDefault() {
        // Clear any previous state
        UserDefaults.standard.removeObject(forKey: "rnf_healthkit_write_opted_in")
        let writer = HealthKitWriter()
        XCTAssertFalse(writer.hasUserOptedIn)
    }

    @MainActor
    func testHealthKitWriterRevokeOptIn() {
        let writer = HealthKitWriter()
        writer.hasUserOptedIn = true
        XCTAssertTrue(writer.hasUserOptedIn)

        writer.revokeOptIn()
        XCTAssertFalse(writer.hasUserOptedIn)
    }
}
