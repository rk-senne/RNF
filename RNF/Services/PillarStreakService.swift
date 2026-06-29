import Foundation

// P20-EXP-16a: Multi-pillar streak data model
struct PillarStreaks: Codable {
    var habits: Int = 0
    var workouts: Int = 0
    var reading: Int = 0
    var focus: Int = 0
    var overall: Int = 0
}

// P20-EXP-16b: Streak calculation system
struct PillarStreakService {
    private static let key = "rnf_pillar_streaks"
    private static let datesKey = "rnf_pillar_dates"

    static func load() -> PillarStreaks {
        guard let data = UserDefaults.standard.data(forKey: key),
              let s = try? JSONDecoder().decode(PillarStreaks.self, from: data)
        else { return PillarStreaks() }
        return s
    }

    static func save(_ streaks: PillarStreaks) {
        if let data = try? JSONEncoder().encode(streaks) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func recordCompletion(pillar: String) {
        let today = todayString()
        var dates = loadDates()
        dates["\(pillar)_\(today)"] = true
        saveDates(dates)
        recalculate()
    }

    private static func recalculate() {
        var streaks = PillarStreaks()
        streaks.habits = consecutiveDays(for: "habits")
        streaks.workouts = consecutiveDays(for: "workouts")
        streaks.reading = consecutiveDays(for: "reading")
        streaks.focus = consecutiveDays(for: "focus")
        streaks.overall = min(streaks.habits, min(streaks.workouts, streaks.reading))
        save(streaks)
    }

    private static func consecutiveDays(for pillar: String) -> Int {
        let dates = loadDates()
        var count = 0
        var day = Date()
        let cal = Calendar.current
        for _ in 0..<365 {
            let key = "\(pillar)_\(string(from: day))"
            if dates[key] == true {
                count += 1
                day = cal.date(byAdding: .day, value: -1, to: day) ?? day
            } else { break }
        }
        return count
    }

    private static func loadDates() -> [String: Bool] {
        UserDefaults.standard.dictionary(forKey: datesKey) as? [String: Bool] ?? [:]
    }
    private static func saveDates(_ d: [String: Bool]) {
        UserDefaults.standard.set(d, forKey: datesKey)
    }
    private static func todayString() -> String { string(from: Date()) }
    private static func string(from date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
    }
}
