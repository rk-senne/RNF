import SwiftUI

struct AscensionView: View {

    @EnvironmentObject var game: GameState
    @State private var glow = false

    var body: some View {

        VStack(spacing: 30) {

            Spacer()

            ZStack {

                Circle()
                    .fill(levelColor().opacity(0.25))
                    .frame(width: glow ? 240 : 200)
                    .blur(radius: glow ? 45 : 25)
                    .animation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                        value: glow
                    )

                VStack(spacing: 8) {

                    Text("LEVEL \(game.level)")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(rankTitle())
                        .font(.title3)
                        .foregroundColor(.gray)

                }

            }
            .onAppear { glow.toggle() }

            VStack(alignment: .leading, spacing: 8) {

                Text("XP PROGRESS")
                    .font(.caption)
                    .foregroundColor(.gray)

                ProgressView(value: Double(game.xp), total: Double(game.xpToNext))
                    .tint(levelColor())

                Text("\(game.xp) / \(game.xpToNext) XP")
                    .font(.caption2)
                    .foregroundColor(.gray)

            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 10) {

                Text("CHARACTER STATS")
                    .font(.caption)
                    .foregroundColor(.gray)

                DisciplineRadarChart(
                    stats: radarValues()
                )
                .frame(height: 220)

            }
            .padding(.horizontal)

            VStack(spacing: 8) {

                Text("🔥 \(game.streak) Day Streak")
                    .font(.headline)

                Text("Forged Discipline")
                    .font(.caption)
                    .foregroundColor(.gray)

            }

            VStack(alignment: .leading, spacing: 6) {

                Text("TITLES")
                    .font(.caption)
                    .foregroundColor(.gray)

                ForEach(game.titles, id: \.self) { title in
                    Text("• \(title)")
                }

            }

            Spacer()

        }
        .navigationTitle("Ascension")

    }

    func levelColor() -> Color {

        switch game.level {

        case 1...4:
            return .yellow

        case 5...9:
            return .purple

        case 10...14:
            return .red

        case 15...19:
            return .blue

        default:
            return .white
        }

    }

    func rankTitle() -> String {

        switch game.level {

        case 1...4:
            return "Disciple"

        case 5...9:
            return "Awakened"

        case 10...14:
            return "Ascendant"

        case 15...19:
            return "Warlord"

        default:
            return "Apex"
        }

    }

    func radarValues() -> [Double] {

        let maxStat = 20.0

        return [
            Double(game.stats.strength) / maxStat,
            Double(game.stats.discipline) / maxStat,
            Double(game.stats.focus) / maxStat,
            Double(game.stats.energy) / maxStat,
            Double(game.stats.wisdom) / maxStat,
            Double(game.stats.mind) / maxStat,
            Double(game.stats.spirit) / maxStat
        ]

    }

}
