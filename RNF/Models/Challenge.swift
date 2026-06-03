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

extension Challenge {

    static let totalDays = 90

    static func active(
        userId: UUID,
        startDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Challenge {
        let normalizedStartDate = calendar.startOfDay(for: startDate)

        return Challenge(
            id: UUID(),
            user_id: userId,
            start_date: normalizedStartDate,
            end_date: endDate(for: normalizedStartDate, calendar: calendar),
            current_day: 1,
            status: .active,
            created_at: nil
        )
    }

    static func endDate(
        for startDate: Date,
        calendar: Calendar = .current
    ) -> Date {
        let normalizedStartDate = calendar.startOfDay(for: startDate)

        return calendar.date(
            byAdding: .day,
            value: totalDays - 1,
            to: normalizedStartDate
        ) ?? normalizedStartDate
    }

    var normalizedCurrentDay: Int {
        min(max(current_day, 1), Self.totalDays)
    }

    var progress: Double {
        Double(normalizedCurrentDay) / Double(Self.totalDays)
    }

    var isActive: Bool {
        status == .active
    }

    var isCompleted: Bool {
        status == .completed || normalizedCurrentDay >= Self.totalDays
    }

    var isFinalDay: Bool {
        normalizedCurrentDay >= Self.totalDays
    }

    func advancingOneDay() -> Challenge {
        let nextDay = min(normalizedCurrentDay + 1, Self.totalDays)

        return mapped(
            currentDay: nextDay,
            status: nextDay >= Self.totalDays ? .completed : status
        )
    }

    func completing() -> Challenge {
        mapped(
            currentDay: Self.totalDays,
            status: .completed
        )
    }

    func restarting(
        startDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Challenge {
        let normalizedStartDate = calendar.startOfDay(for: startDate)

        return Challenge(
            id: id,
            user_id: user_id,
            start_date: normalizedStartDate,
            end_date: Self.endDate(for: normalizedStartDate, calendar: calendar),
            current_day: 1,
            status: .active,
            created_at: created_at
        )
    }

    func mapped(
        currentDay: Int? = nil,
        status: Status? = nil
    ) -> Challenge {
        Challenge(
            id: id,
            user_id: user_id,
            start_date: start_date,
            end_date: end_date,
            current_day: currentDay ?? current_day,
            status: status ?? self.status,
            created_at: created_at
        )
    }

}
