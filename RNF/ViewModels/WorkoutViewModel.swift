import Foundation
import Combine

@MainActor
protocol WorkoutCompleting: AnyObject {
    func configure(gameState: GameState)
    func completeWorkout(
        durationSeconds: Int,
        elapsedSeconds: Int,
        date: Date
    ) async -> WorkoutCompletionResult?
}

extension WorkoutEngine: WorkoutCompleting {
}

@MainActor
final class WorkoutViewModel: ObservableObject {

    enum CompletionState: Equatable {
        case timing
        case finalizing
        case completed(Int)
        case failed(String)
    }

    @Published private(set) var remainingSeconds: Int
    @Published private(set) var elapsedSeconds = 0
    @Published var isRunning = true
    @Published private(set) var completionState: CompletionState = .timing

    let durationSeconds: Int

    private let workoutCompleter: WorkoutCompleting

    init(durationSeconds: Int) {
        let sanitizedDuration = max(durationSeconds, 0)
        self.durationSeconds = sanitizedDuration
        self.remainingSeconds = sanitizedDuration
        self.workoutCompleter = WorkoutEngine()
    }

    init(
        durationSeconds: Int,
        workoutCompleter: WorkoutCompleting
    ) {
        let sanitizedDuration = max(durationSeconds, 0)
        self.durationSeconds = sanitizedDuration
        self.remainingSeconds = sanitizedDuration
        self.workoutCompleter = workoutCompleter
    }

    var timerText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        WorkoutDurationValidator.completionRatio(
            durationSeconds: durationSeconds,
            elapsedSeconds: elapsedSeconds
        )
    }

    var isComplete: Bool {
        if case .completed = completionState {
            return true
        }

        return false
    }

    var isFinalizing: Bool {
        if case .finalizing = completionState {
            return true
        }

        return false
    }

    var completedXP: Int? {
        if case let .completed(xpAwarded) = completionState {
            return xpAwarded
        }

        return nil
    }

    var errorMessage: String? {
        if case let .failed(message) = completionState {
            return message
        }

        return nil
    }

    var primaryControlTitle: String {
        isRunning ? "Pause" : "Resume"
    }

    var primaryControlIcon: String {
        isRunning ? "pause.fill" : "play.fill"
    }

    var canToggleTimer: Bool {
        completionState == .timing
    }

    func configure(gameState: GameState) {
        workoutCompleter.configure(gameState: gameState)
    }

    func toggleRunning() {
        guard canToggleTimer else {
            return
        }

        isRunning.toggle()
    }

    func runTimer() async {
        guard isRunning, completionState == .timing else {
            return
        }

        while isRunning && remainingSeconds > 0 && !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            guard isRunning, remainingSeconds > 0, !Task.isCancelled else {
                return
            }

            advanceTimerByOneSecond()
        }

        if remainingSeconds == 0, completionState == .timing {
            await completeSession()
        }
    }

    func advanceTimerByOneSecond() {
        guard isRunning, completionState == .timing, remainingSeconds > 0 else {
            return
        }

        remainingSeconds -= 1
        elapsedSeconds += 1
    }

    func endSession(date: Date = Date()) async -> Bool {
        guard
            WorkoutDurationValidator.isComplete(
                durationSeconds: durationSeconds,
                elapsedSeconds: elapsedSeconds
            )
        else {
            isRunning = false
            return false
        }

        await completeSession(date: date)
        return true
    }

    func completeSession(date: Date = Date()) async {
        guard completionState != .finalizing, !isComplete else {
            return
        }

        isRunning = false
        completionState = .finalizing

        let result = await workoutCompleter.completeWorkout(
            durationSeconds: durationSeconds,
            elapsedSeconds: max(elapsedSeconds, durationSeconds),
            date: date
        )

        if let result {
            completionState = .completed(result.xpAwarded)
        } else {
            completionState = .failed("Workout could not be saved")
        }
    }

    func retryCompletion(date: Date = Date()) async {
        await completeSession(date: date)
    }

}
