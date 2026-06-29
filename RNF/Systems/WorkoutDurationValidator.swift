import Foundation

struct WorkoutDurationValidator {

    static func completionRatio(
        durationSeconds: Int,
        elapsedSeconds: Int
    ) -> Double {
        guard durationSeconds > 0 else {
            return 0
        }

        return min(max(Double(elapsedSeconds) / Double(durationSeconds), 0), 1)
    }

    static func isComplete(
        durationSeconds: Int,
        elapsedSeconds: Int
    ) -> Bool {
        completionRatio(
            durationSeconds: durationSeconds,
            elapsedSeconds: elapsedSeconds
        ) >= WorkoutSession.completionThreshold
    }

}
