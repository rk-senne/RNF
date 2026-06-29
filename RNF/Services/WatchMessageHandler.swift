import Foundation

/// Handles incoming Watch messages on the iPhone side with idempotency guarantees.
@MainActor
final class WatchMessageHandler {

    private let dailyLogService: DailyLogService
    private let workoutService: WorkoutService
    private var processedKeys: Set<UUID> = []

    init(dailyLogService: DailyLogService = DailyLogService(), workoutService: WorkoutService = WorkoutService()) {
        self.dailyLogService = dailyLogService
        self.workoutService = workoutService
    }

    func handleHabitCompletion(_ message: WatchHabitCompletionMessage, userId: UUID) async -> Bool {
        guard !processedKeys.contains(message.idempotencyKey) else {
            return false // already processed
        }

        let completion = HabitCompletion(
            id: message.idempotencyKey,
            user_id: userId,
            habit_id: message.habitID,
            completed_at: message.completedAt,
            date: message.completedAt.startOfDay,
            xp_awarded: 10
        )

        do {
            guard let recorded = try await dailyLogService.recordHabitCompletion(completion) else {
                return false
            }
            // If IDs match, this is a fresh completion. If different, it was deduplicated.
            processedKeys.insert(message.idempotencyKey)
            return recorded.id == message.idempotencyKey
        } catch {
            return false
        }
    }

    func handleWorkoutAction(_ message: WatchWorkoutMessage, userId: UUID) async -> Bool {
        guard !processedKeys.contains(message.idempotencyKey) else { return false }

        switch message.action {
        case .complete:
            let result = await workoutService.completeWorkoutSafe(userId: userId)
            if result.error == nil {
                processedKeys.insert(message.idempotencyKey)
                return true
            }
            return false
        case .start, .stop:
            processedKeys.insert(message.idempotencyKey)
            return true
        }
    }
}
