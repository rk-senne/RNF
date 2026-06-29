import SwiftUI

struct CalendarGridView: View {

    let month: Date
    let statusesByDay: [Date: DailyLogStatus]
    var onDayTapped: ((Date, DailyLogStatus) -> Void)?
    private let calendar: Calendar

    init(
        month: Date = Date(),
        statusesByDay: [Date: DailyLogStatus] = [:],
        onDayTapped: ((Date, DailyLogStatus) -> Void)? = nil,
        calendar: Calendar = .current
    ) {
        self.month = month
        self.statusesByDay = statusesByDay
        self.onDayTapped = onDayTapped
        self.calendar = calendar
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            HStack(alignment: .firstTextBaseline) {
                Text(monthTitle)
                    .font(RNFFont.section)

                Spacer()

                Text("\(completedDays) / \(monthDays.count)")
                    .font(RNFFont.caption)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: weekdayColumns, spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(RNFFont.pillMedium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(0..<leadingBlankCount, id: \.self) { _ in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }

                ForEach(monthDays, id: \.self) { day in
                    CalendarDayCell(
                        day: calendar.component(.day, from: day),
                        status: status(for: day),
                        isToday: calendar.isDateInToday(day)
                    )
                    .onTapGesture {
                        onDayTapped?(day, status(for: day))
                    }
                }
            }

        }

    }

    private var weekdayColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    }

    private var monthTitle: String {
        month.formatted(.dateTime.month(.wide).year())
    }

    private var monthStart: Date {
        calendar.date(
            from: calendar.dateComponents([.year, .month], from: month)
        ) ?? calendar.startOfDay(for: month)
    }

    private var monthDays: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthStart)
        }
    }

    private var leadingBlankCount: Int {
        let weekday = calendar.component(.weekday, from: monthStart)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let startIndex = max(calendar.firstWeekday - 1, 0)
        return Array(symbols[startIndex...] + symbols[..<startIndex])
    }

    private var completedDays: Int {
        monthDays.filter { status(for: $0) == .complete || status(for: $0) == .forgiven }.count
    }

    private func status(for date: Date) -> DailyLogStatus {
        statusesByDay[calendar.startOfDay(for: date)] ?? .missed
    }

}

private struct CalendarDayCell: View {

    let day: Int
    let status: DailyLogStatus
    let isToday: Bool
    @State private var pulse = false

    var body: some View {

        ZStack(alignment: .topTrailing) {
            Text("\(day)")
                .font(RNFFont.captionBold)
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity, minHeight: 36, minWidth: 36)
                .aspectRatio(1, contentMode: .fit)
                .background {
                    Circle()
                        .fill(backgroundColor)
                }
                .overlay {
                    Circle()
                        .strokeBorder(borderColor, lineWidth: isToday ? 2 : 1)
                        .opacity(isToday && pulse ? 0.4 : 1)
                }

            if status == .forgiven {
                Circle()
                    .fill(Color(red: 0.1, green: 0.45, blue: 0.25))
                    .frame(width: 7, height: 7)
                    .offset(x: -4, y: 4)
            }
        }
        .accessibilityLabel("Day \(day), \(status.rawValue)")
        .accessibilityAddTraits(.isButton)
        .onAppear {
            guard isToday, !UIAccessibility.isReduceMotionEnabled else { return }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }

    }

    private var backgroundColor: Color {
        switch status {
        case .complete:
            return RNFColors.success
        case .partial:
            return Color(red: 0.75, green: 0.91, blue: 0.68)
        case .missed:
            return Color(.secondarySystemFill)
        case .forgiven:
            return RNFColors.success
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .complete, .forgiven:
            return .white
        case .partial:
            return Color(red: 0.08, green: 0.32, blue: 0.18)
        case .missed:
            return .secondary
        }
    }

    private var borderColor: Color {
        isToday ? Color.primary.opacity(0.55) : RNFColors.borderSubtle
    }

}

#Preview {
    let calendar = Calendar.current
    let month = Date()
    let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
    let sampleStatuses: [Date: DailyLogStatus] = [
        start: .complete,
        calendar.date(byAdding: .day, value: 1, to: start) ?? start: .partial,
        calendar.date(byAdding: .day, value: 2, to: start) ?? start: .forgiven
    ]

    CalendarGridView(month: month, statusesByDay: sampleStatuses)
        .padding()
}
