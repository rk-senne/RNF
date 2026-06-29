import Foundation

struct ReadingProfileService {
    private static let key = "rnf_reading_profile"

    static func load() -> ReadingProfile {
        guard let data = UserDefaults.standard.data(forKey: key),
              let profile = try? JSONDecoder().decode(ReadingProfile.self, from: data)
        else { return ReadingProfile() }
        return profile
    }

    static func save(_ profile: ReadingProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func logReading(pages: Int = 10) {
        var profile = load()
        let today = DateFormatter.rnfShort.string(from: Date())
        profile.totalPages += pages
        if profile.lastReadDate == DateFormatter.rnfShort.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()) {
            profile.readingStreak += 1
        } else if profile.lastReadDate != today {
            profile.readingStreak = 1
        }
        profile.lastReadDate = today
        save(profile)
    }

    static func completeBook() {
        var profile = load()
        profile.booksCompleted += 1
        profile.currentBook = ""
        profile.currentBookStartDate = ""
        save(profile)
    }

    static func setCurrentBook(_ name: String) {
        var profile = load()
        profile.currentBook = name
        profile.currentBookStartDate = DateFormatter.rnfShort.string(from: Date())
        save(profile)
    }
}

private extension DateFormatter {
    static let rnfShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
