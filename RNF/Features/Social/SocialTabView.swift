import SwiftUI

struct SocialTabView: View {
    @State private var selectedTab = 0

    var guild: Guild?
    var leaderboard: [LeaderboardEntry] = []
    var challenges: [SocialChallenge] = []

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedTab) {
                Text("Guild").tag(0)
                Text("Leaderboard").tag(1)
                Text("Challenges").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            switch selectedTab {
            case 0: GuildView(guild: guild)
            case 1: LeaderboardView(entries: leaderboard)
            case 2: SocialChallengeView(challenges: challenges)
            default: EmptyView()
            }
        }
        .navigationTitle("Social")
    }
}
