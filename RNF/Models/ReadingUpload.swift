import Foundation

struct ReadingUpload: Codable, Identifiable {

    let id: UUID
    let user_id: UUID
    let image_url: String
    let date: Date
    var created_at: Date? = nil

}
