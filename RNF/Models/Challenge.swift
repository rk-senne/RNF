// FUTURE TASK: P6-MDL-02
// This file is intentionally not integrated yet

import Foundation

struct Challenge: Codable, Identifiable {

    enum Status: String, Codable {
        case active
        case completed
        case reset
    }

    let id: UUID
    let user_id: UUID
    let start_date: Date
    let end_date: Date
    let current_day: Int
    let status: Status
    let created_at: Date?

}
