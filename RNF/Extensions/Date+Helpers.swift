import Foundation

extension Date {

    // MARK: Start of Day

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    // MARK: End of Day

    var endOfDay: Date {
        Calendar.current.date(
            byAdding: DateComponents(day: 1, second: -1),
            to: startOfDay
        )!
    }

    // MARK: Is Today

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    // MARK: Is Yesterday

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    // MARK: Days Between

    func daysBetween(_ date: Date) -> Int {

        let calendar = Calendar.current

        let start = calendar.startOfDay(for: self)
        let end = calendar.startOfDay(for: date)

        let components = calendar.dateComponents(
            [.day],
            from: start,
            to: end
        )

        return components.day ?? 0
    }

    // MARK: Add Days

    func addingDays(_ days: Int) -> Date {

        Calendar.current.date(
            byAdding: .day,
            value: days,
            to: self
        )!
    }

    // MARK: Start of Month

    var startOfMonth: Date {

        let components = Calendar.current.dateComponents(
            [.year, .month],
            from: self
        )

        return Calendar.current.date(from: components)!
    }

    // MARK: End of Month

    var endOfMonth: Date {

        Calendar.current.date(
            byAdding: DateComponents(month: 1, day: -1),
            to: startOfMonth
        )!
    }

    // MARK: Format Date

    func formatted(_ format: String) -> String {

        let formatter = DateFormatter()
        formatter.dateFormat = format

        return formatter.string(from: self)
    }

}
