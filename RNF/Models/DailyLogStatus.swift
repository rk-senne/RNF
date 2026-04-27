import Foundation

enum DailyLogStatus: String, Codable, CaseIterable {
    case complete
    case partial
    case missed
    case forgiven
}
