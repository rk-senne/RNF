import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var game: GameState

    var body: some View {
        List {
            // P20-EXP-04d: Discipline Card entry
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

            ThemeSettingsView()
            VoiceSettingsView()
            HealthSettingsSection()
        }
        .navigationTitle("Profile")
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
