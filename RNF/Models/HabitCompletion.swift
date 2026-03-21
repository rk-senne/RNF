import Foundation

struct HabitCompletion: Codable, Identifiable {

    let id: UUID
    let user_id: UUID?
    let habit_id: UUID
    let completed_at: Date
    let date: Date
    let xp_awarded: Int
    var created_at: Date? = nil

}
