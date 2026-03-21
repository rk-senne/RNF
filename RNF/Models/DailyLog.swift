import Foundation

struct DailyLog: Codable, Identifiable {

    enum Status: String, Codable {
        case complete
        case partial
        case missed
        case forgiven
    }

    let id: UUID
    var user_id: UUID?
    var date: Date
    var habits_completed: Int
    var habits_required: Int
    var workout_completed: Bool
    var reading_completed: Bool
    var forgiveness_used: Bool
    var xp_earned: Int
    var status: Status
    var created_at: Date?

}

extension DailyLog {

    static func today(userID: UUID? = nil, goal: Int) -> DailyLog {

        DailyLog(
            id: UUID(),
            user_id: userID,
            date: Date().startOfDay,
            habits_completed: 0,
            habits_required: goal,
            workout_completed: false,
            reading_completed: false,
            forgiveness_used: false,
            xp_earned: 0,
            status: .partial,
            created_at: nil
        )

    }

}
