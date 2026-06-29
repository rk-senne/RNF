import Foundation

struct HealthWorkoutSummary: Codable, Identifiable {
    let id: UUID
    let healthKitUUID: String
    let workoutType: String
    let startDate: Date
    let endDate: Date
    let durationSeconds: Int
    let activeEnergyBurned: Double?
    var accepted: Bool

    var duration: TimeInterval { Double(durationSeconds) }
}

struct WatchDailySnapshot: Codable {
    let date: Date
    let level: Int
    let streak: Int
    let dailyCompleted: Int
    let dailyGoal: Int
    let challengeDay: Int?
    let habits: [WatchHabitSummary]
}

struct WatchHabitSummary: Codable, Identifiable {
    let id: UUID
    let name: String
    let completed: Bool
    let xpReward: Int
}

struct WatchHabitCompletionMessage: Codable {
    let idempotencyKey: UUID
    let habitID: UUID
    let completedAt: Date
}

struct WatchWorkoutMessage: Codable {
    let idempotencyKey: UUID
    let action: Action
    let durationSeconds: Int?

    enum Action: String, Codable {
        case start
        case stop
        case complete
    }
}
