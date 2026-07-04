import SwiftUI

/// Profile tab with sectioned NavigationStack.
/// Replaces the old flat ProfileView as the 5th tab.
struct ProfileTabView: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        NavigationStack {
            List {
                identitySection
                if ReleaseGate.isEnabled(.skillTree) {
                    progressSection
                }
                if ReleaseGate.isEnabled(.guilds) {
                    socialSection
                }
                toolsSection
                settingsSection
            }
            .navigationTitle("Profile")
        }
    }

    private var identitySection: some View {
        Section("Identity") {
            NavigationLink {
                DisciplineCardView(
                    level: game.level,
                    streak: game.streak,
                    tierName: StreakTierSystem.tier(for: game.streak).rawValue,
                    tierIcon: StreakTierSystem.icon(for: StreakTierSystem.tier(for: game.streak)),
                    stats: statsArray,
                    tagline: game.titles.first ?? QuoteEngine.todayQuote().text
                )
            } label: {
                Label("My Discipline Card", systemImage: "person.crop.rectangle")
            }

            HStack {
                Label("Level", systemImage: "star.fill")
                Spacer()
                Text("\(game.level)")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Streak", systemImage: "flame.fill")
                Spacer()
                Text("\(game.streak) days")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var progressSection: some View {
        Section("Progress") {
            Text("Coming soon")
        }
    }

    private var socialSection: some View {
        Section("Social") {
            NavigationLink {
                SocialTabView()
            } label: {
                Label("Guild & Leaderboard", systemImage: "person.3.fill")
            }
        }
    }

    private var toolsSection: some View {
        Section("Tools") {
            if ReleaseGate.isEnabled(.insights) {
                NavigationLink {
                    FocusTimerView(sessionType: .standard)
                } label: {
                    Label("Focus Timer", systemImage: "timer")
                }

                NavigationLink {
                    DiscoveryLogView()
                } label: {
                    Label("Discoveries", systemImage: "sparkles")
                }

                NavigationLink {
                    ArcArchiveView()
                } label: {
                    Label("Arc Archive", systemImage: "archivebox.fill")
                }
            }

            NavigationLink {
                SettingsView()
            } label: {
                Label("Settings", systemImage: "gear")
            }
        }
    }

    private var settingsSection: some View {
        Section("Account") {
            NavigationLink {
                AccountDeletionView()
            } label: {
                Label("Delete Account", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        }
    }

    private var statsArray: [Double] {
        let s = game.stats
        let max = 20.0
        return [
            Double(s.strength) / max,
            Double(s.discipline) / max,
            Double(s.focus) / max,
            Double(s.energy) / max,
            Double(s.wisdom) / max,
            Double(s.mind) / max,
            Double(s.spirit) / max
        ]
    }
}
