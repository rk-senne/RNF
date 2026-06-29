import Foundation

enum AnalyticsTimestamp {
    private static let formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()

    static func string(for date: Date) -> String {
        formatter.string(from: date)
    }
}
