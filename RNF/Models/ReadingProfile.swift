import Foundation

struct ReadingProfile: Codable {
    var currentBook: String = ""
    var currentBookStartDate: String = ""
    var totalPages: Int = 0
    var booksCompleted: Int = 0
    var readingStreak: Int = 0
    var lastReadDate: String = ""
}
