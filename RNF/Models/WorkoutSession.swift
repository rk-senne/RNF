import Foundation

struct WorkoutSession: Codable, Identifiable {

    enum Kind: String, Codable {
        case quickChallenge = "quick_challenge"
        case timed
    }

    enum Status: String, Codable {
        case planned
        case active
        case completed
        case cancelled
    }

    let id: UUID
    let user_id: UUID?
    let kind: Kind
    let title: String
    let duration_seconds: Int
    let elapsed_seconds: Int
    let started_at: Date?
    let completed_at: Date?
    let xp_awarded: Int
    let status: Status

}

extension WorkoutSession {

    static let completionThreshold = 0.8

    var completionRatio: Double {
        guard duration_seconds > 0 else {
            return 0
        }

        return min(Double(elapsed_seconds) / Double(duration_seconds), 1)
    }

    var meetsCompletionThreshold: Bool {
        completionRatio >= Self.completionThreshold
    }

}
