import Foundation

struct Guild: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    var memberCount: Int
    var totalXP: Int
    var created_by: UUID
    var created_at: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case memberCount = "member_count"
        case totalXP = "total_xp"
        case created_by, created_at
    }
}

struct GuildMember: Codable, Identifiable {
    let id: UUID
    let guild_id: UUID
    let user_id: UUID
    var role: Role
    var joined_at: Date?

    enum Role: String, Codable {
        case leader
        case member
    }
}

struct LeaderboardEntry: Codable, Identifiable {
    let id: UUID
    let user_id: UUID
    let username: String?
    let level: Int
    let xp_total: Int
    let streak: Int
    var rank: Int
}

struct SocialChallenge: Codable, Identifiable {
    let id: UUID
    let guild_id: UUID
    let title: String
    let description: String?
    let target_completions: Int
    var current_completions: Int
    var status: Status
    var start_date: Date
    var end_date: Date
    var created_at: Date?

    enum Status: String, Codable {
        case active
        case completed
        case expired
    }

    var progress: Double {
        guard target_completions > 0 else { return 0 }
        return min(Double(current_completions) / Double(target_completions), 1.0)
    }
}
