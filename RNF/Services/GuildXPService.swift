import Foundation
import os

final class GuildXPService {

    private let supabase: SupabaseService
    private let guildService: GuildService

    init(supabase: SupabaseService = .shared, guildService: GuildService = GuildService()) {
        self.supabase = supabase
        self.guildService = guildService
    }

    func contributeXP(userId: UUID, xpAmount: Int) async {
        do {
            guard let guild = try await guildService.fetchUserGuild(userId: userId) else { return }
            try await supabase.db.rpc("increment_guild_xp", params: ["guild_uuid": guild.id.uuidString, "amount": String(xpAmount)]).execute()
        } catch {
            RNFLogger.sync.warning("Guild XP contribution failed: \(error.localizedDescription)")
        }
    }
}
