import Foundation
import Combine

@MainActor
final class WorkoutViewModel: ObservableObject {

    @Published var persistenceError: RNFServiceError?

    private let workoutService: WorkoutService

    init(workoutService: WorkoutService = WorkoutService()) {
        self.workoutService = workoutService
    }

    func completeWorkout(userId: UUID, durationSeconds: Int, elapsedSeconds: Int, date: Date = Date()) async {
        let result = await workoutService.completeWorkoutSafe(userId: userId, date: date)
        persistenceError = result.error
    }

    func dismissError() {
        persistenceError = nil
    }
}
