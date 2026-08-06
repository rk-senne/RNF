import Foundation
import os

// P20-EXP-10a: Social presence provider for guild activity
@MainActor
final class SocialPresenceProvider: ObservableObject {
    @Published var guildMembersCompletedToday: Int = 0
    @Published var isLoaded = false
    private let guildService = GuildService()

    func refresh(userId: UUID) async {
        guard !isLoaded else { return }
        do {
            guard let guild = try await guildService.fetchUserGuild(userId: userId) else {
                isLoaded = true
                return
            }
            let board = try await guildService.fetchGuildLeaderboard(guildId: guild.id)
            guildMembersCompletedToday = min(board.count, 12)
        } catch {
            RNFLogger.social.error("SocialPresenceProvider.refresh failed: \(error.localizedDescription)")
        }
        isLoaded = true
    }
}
