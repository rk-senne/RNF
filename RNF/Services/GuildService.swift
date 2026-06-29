import Foundation

final class GuildService {

    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func createGuild(name: String, description: String?, createdBy: UUID) async throws -> Guild {
        let guild = Guild(id: UUID(), name: name, description: description, memberCount: 1, totalXP: 0, created_by: createdBy, created_at: nil)
        let created: Guild = try await supabase.client
            .from("guilds")
            .insert(guild)
            .select()
            .single()
            .execute()
            .value

        let member = GuildMember(id: UUID(), guild_id: created.id, user_id: createdBy, role: .leader, joined_at: nil)
        try await supabase.client.from("guild_members").insert(member).execute()

        return created
    }

    func joinGuild(guildId: UUID, userId: UUID) async throws {
        let member = GuildMember(id: UUID(), guild_id: guildId, user_id: userId, role: .member, joined_at: nil)
        try await supabase.client.from("guild_members").insert(member).execute()
    }

    func fetchGuild(guildId: UUID) async throws -> Guild? {
        let guilds: [Guild] = try await supabase.client
            .from("guilds").select().eq("id", value: guildId.uuidString).limit(1).execute().value
        return guilds.first
    }

    func fetchUserGuild(userId: UUID) async throws -> Guild? {
        let members: [GuildMember] = try await supabase.client
            .from("guild_members").select().eq("user_id", value: userId.uuidString).limit(1).execute().value
        guard let membership = members.first else { return nil }
        return try await fetchGuild(guildId: membership.guild_id)
    }

    func fetchLeaderboard(limit: Int = 20) async throws -> [LeaderboardEntry] {
        struct UserRow: Decodable {
            let id: UUID
            let display_name: String?
            let xp_total: Int
            let level: Int
            let current_streak: Int
        }
        let rows: [UserRow] = try await supabase.client
            .from("users")
            .select("id, display_name, xp_total, level, current_streak")
            .order("xp_total", ascending: false)
            .limit(limit)
            .execute()
            .value
        return rows.enumerated().map { index, row in
            LeaderboardEntry(
                id: row.id, user_id: row.id, username: row.display_name,
                level: row.level, xp_total: row.xp_total,
                streak: row.current_streak, rank: index + 1
            )
        }
    }

    func fetchGuildLeaderboard(guildId: UUID) async throws -> [LeaderboardEntry] {
        struct MemberRow: Decodable { let user_id: UUID }
        let members: [MemberRow] = try await supabase.client
            .from("guild_members")
            .select("user_id")
            .eq("guild_id", value: guildId.uuidString)
            .execute()
            .value
        let memberIds = members.map(\.user_id)
        guard !memberIds.isEmpty else { return [] }

        let full = try await fetchLeaderboard(limit: 100)
        return full.filter { memberIds.contains($0.user_id) }
            .enumerated()
            .map { index, entry in
                LeaderboardEntry(id: entry.id, user_id: entry.user_id, username: entry.username,
                                 level: entry.level, xp_total: entry.xp_total,
                                 streak: entry.streak, rank: index + 1)
            }
    }
}
