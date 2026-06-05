import Foundation
import XCTest
@testable import RNF

@MainActor
final class WorkoutViewModelTests: XCTestCase {

    func testCompleteSessionShowsFinalizingUntilCompleterSucceeds() async {
        let completer = ControllableWorkoutCompleter()
        let viewModel = WorkoutViewModel(
            durationSeconds: 100,
            workoutCompleter: completer
        )

        let task = Task {
            await viewModel.completeSession(date: Self.date)
        }

        await Task.yield()

        XCTAssertEqual(viewModel.completionState, .finalizing)
        XCTAssertFalse(viewModel.isComplete)
        XCTAssertEqual(completer.completedDurationSeconds, 100)
        XCTAssertEqual(completer.completedElapsedSeconds, 100)

        completer.complete(with: Self.completionResult(xpAwarded: 15))
        await task.value

        XCTAssertEqual(viewModel.completionState, .completed(15))
        XCTAssertTrue(viewModel.isComplete)
    }

    func testCompleteSessionAppliesCompletionResultToConfiguredGameState() async {
        let viewModel = WorkoutViewModel(
            durationSeconds: 100,
            workoutCompleter: StubWorkoutCompleter(result: Self.completionResult(xpAwarded: 15))
        )
        let gameState = GameState()
        viewModel.configure(gameState: gameState)

        await viewModel.completeSession(date: Self.date)

        XCTAssertEqual(gameState.profile.xp_total, 15)
        XCTAssertEqual(gameState.level, 1)
        XCTAssertEqual(gameState.xp, 15)
        XCTAssertTrue(gameState.dailyLog.workout_completed)
    }

    func testCompleteSessionSurfacesFailureWithoutCompletion() async {
        let viewModel = WorkoutViewModel(
            durationSeconds: 100,
            workoutCompleter: StubWorkoutCompleter(result: nil)
        )

        await viewModel.completeSession(date: Self.date)

        XCTAssertEqual(viewModel.completionState, .failed("Workout could not be saved"))
        XCTAssertEqual(viewModel.errorMessage, "Workout could not be saved")
        XCTAssertFalse(viewModel.isComplete)
    }

    func testRetryCompletionCanRecoverAfterFailure() async {
        let completer = SequenceWorkoutCompleter(results: [
            nil,
            Self.completionResult(xpAwarded: 15)
        ])
        let viewModel = WorkoutViewModel(
            durationSeconds: 100,
            workoutCompleter: completer
        )

        await viewModel.completeSession(date: Self.date)
        await viewModel.retryCompletion(date: Self.date)

        XCTAssertEqual(completer.completionCallCount, 2)
        XCTAssertEqual(viewModel.completionState, .completed(15))
        XCTAssertTrue(viewModel.isComplete)
    }

    func testEndSessionOnlyCompletesAfterEightyPercentThreshold() async {
        let completer = StubWorkoutCompleter(result: Self.completionResult(xpAwarded: 15))
        let viewModel = WorkoutViewModel(
            durationSeconds: 100,
            workoutCompleter: completer
        )

        for _ in 0..<79 {
            viewModel.advanceTimerByOneSecond()
        }

        let didAttemptEarlyCompletion = await viewModel.endSession(date: Self.date)

        XCTAssertFalse(didAttemptEarlyCompletion)
        XCTAssertNil(completer.completedDurationSeconds)

        let thresholdViewModel = WorkoutViewModel(
            durationSeconds: 100,
            workoutCompleter: completer
        )

        for _ in 0..<80 {
            thresholdViewModel.advanceTimerByOneSecond()
        }

        let didAttemptThresholdCompletion = await thresholdViewModel.endSession(date: Self.date)

        XCTAssertTrue(didAttemptThresholdCompletion)
        XCTAssertEqual(completer.completedDurationSeconds, 100)
        XCTAssertEqual(completer.completedElapsedSeconds, 100)
    }

    func testTimerTickUpdatesDisplayState() {
        let viewModel = WorkoutViewModel(
            durationSeconds: 100,
            workoutCompleter: StubWorkoutCompleter()
        )

        viewModel.advanceTimerByOneSecond()

        XCTAssertEqual(viewModel.remainingSeconds, 99)
        XCTAssertEqual(viewModel.elapsedSeconds, 1)
        XCTAssertEqual(viewModel.timerText, "01:39")
        XCTAssertEqual(viewModel.progress, 0.01, accuracy: 0.001)
    }

    private static let date = Date(timeIntervalSince1970: 0)

    private static func completionResult(xpAwarded: Int) -> WorkoutCompletionResult {
        let userId = UUID()
        let profile = Profile(
            id: userId,
            email: "workout@example.com",
            xp_total: xpAwarded,
            level: 1,
            streak: 0,
            forgiveness_tokens: 0,
            morning_notification_time: nil,
            evening_notification_time: nil,
            strength: 10,
            discipline: 10,
            focus: 10,
            energy: 10,
            wisdom: 10,
            mind: 10,
            spirit: 10,
            created_at: nil
        )

        var dailyLog = DailyLog.today(userID: userId, goal: 3)
        dailyLog.workout_completed = true
        dailyLog.xp_earned = xpAwarded

        return WorkoutCompletionResult(
            dailyLog: dailyLog,
            profile: profile,
            xpAwarded: xpAwarded,
            levelState: XPSystem.levelState(for: xpAwarded),
            advancedChallenge: nil
        )
    }

}

@MainActor
private final class StubWorkoutCompleter: WorkoutCompleting {

    private let result: WorkoutCompletionResult?
    private(set) var configuredGameState: GameState?
    private(set) var completedDurationSeconds: Int?
    private(set) var completedElapsedSeconds: Int?
    private(set) var completedDate: Date?

    init(result: WorkoutCompletionResult? = nil) {
        self.result = result
    }

    func configure(gameState: GameState) {
        configuredGameState = gameState
    }

    func completeWorkout(
        durationSeconds: Int,
        elapsedSeconds: Int,
        date: Date
    ) async -> WorkoutCompletionResult? {
        completedDurationSeconds = durationSeconds
        completedElapsedSeconds = elapsedSeconds
        completedDate = date
        return result
    }

}

@MainActor
private final class SequenceWorkoutCompleter: WorkoutCompleting {

    private var results: [WorkoutCompletionResult?]
    private(set) var completionCallCount = 0

    init(results: [WorkoutCompletionResult?]) {
        self.results = results
    }

    func configure(gameState: GameState) {
    }

    func completeWorkout(
        durationSeconds: Int,
        elapsedSeconds: Int,
        date: Date
    ) async -> WorkoutCompletionResult? {
        completionCallCount += 1

        guard !results.isEmpty else {
            return nil
        }

        return results.removeFirst()
    }

}

@MainActor
private final class ControllableWorkoutCompleter: WorkoutCompleting {

    private var continuation: CheckedContinuation<WorkoutCompletionResult?, Never>?
    private(set) var completedDurationSeconds: Int?
    private(set) var completedElapsedSeconds: Int?

    func configure(gameState: GameState) {
    }

    func completeWorkout(
        durationSeconds: Int,
        elapsedSeconds: Int,
        date: Date
    ) async -> WorkoutCompletionResult? {
        completedDurationSeconds = durationSeconds
        completedElapsedSeconds = elapsedSeconds

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func complete(with result: WorkoutCompletionResult?) {
        continuation?.resume(returning: result)
        continuation = nil
    }

}
