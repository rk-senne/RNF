import Foundation

// P20-EXP-17a: Weekly report data and logic
struct WeeklyReport {
    let daysActive: Int
    let habitsCompleted: Int
    let xpEarned: Int
    let streakLength: Int
    let bestDayXP: Int
    let weekNumber: Int
}

struct WeeklyReportService {
    private static let shownKey = "rnf_weekly_report_shown"

    static func shouldShow() -> Bool {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: Date())
        guard weekday == 2 else { return false } // Monday only
        let weekID = cal.component(.weekOfYear, from: Date())
        let lastShown = UserDefaults.standard.integer(forKey: shownKey)
        return lastShown != weekID
    }

    static func markShown() {
        let weekID = Calendar.current.component(.weekOfYear, from: Date())
        UserDefaults.standard.set(weekID, forKey: shownKey)
    }

    static func generate(profile: Profile, streak: Int) -> WeeklyReport {
        WeeklyReport(
            daysActive: min(streak, 7),
            habitsCompleted: min(streak, 7) * 4,
            xpEarned: min(streak, 7) * 80,
            streakLength: streak,
            bestDayXP: 180,
            weekNumber: Calendar.current.component(.weekOfYear, from: Date()) - 1
        )
    }
}
