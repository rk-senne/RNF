import SwiftUI

struct AscensionView: View {

    @EnvironmentObject private var game: GameState
    private let viewModel = AscensionViewModel()
    @State private var glow = false

    var body: some View {

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                VStack(spacing: 18) {

                    ZStack {

                        Circle()
                            .fill(viewModel.levelColor(for: game.level).opacity(0.18))
                            .frame(width: glow ? 232 : 208)
                            .blur(radius: glow ? 48 : 28)
                            .animation(
                                .easeInOut(duration: 2.2)
                                .repeatForever(autoreverses: true),
                                value: glow
                            )

                        VStack(spacing: 10) {

                            Text("LEVEL \(game.level)")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundStyle(Color.primary)

                            Text(viewModel.rankTitle(for: game.level))
                                .font(.system(size: 22, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.secondary)

                        }

                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                    .onAppear { glow.toggle() }

                    HStack(spacing: 12) {
                        summaryChip(
                            title: "Streak",
                            value: "\(game.streak) days",
                            tint: Color(red: 0.9, green: 0.46, blue: 0.18)
                        )

                        summaryChip(
                            title: "Titles",
                            value: "\(game.titles.count) earned",
                            tint: viewModel.levelColor(for: game.level)
                        )
                    }

                }
                .padding(24)
                .background { surfaceFill }
                .overlay(surfaceBorder)
                .shadow(color: Color.black.opacity(0.06), radius: 24, x: 0, y: 12)

                VStack(alignment: .leading, spacing: 18) {

                    Text("XP PROGRESS")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)

                    ProgressView(value: Double(game.xp), total: Double(max(game.xpToNext, 1)))
                        .tint(viewModel.levelColor(for: game.level))
                        .scaleEffect(x: 1, y: 1.8, anchor: .center)

                    Text("\(game.xp) / \(game.xpToNext) XP")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background { surfaceFill }
                .overlay(surfaceBorder)

                VStack(alignment: .leading, spacing: 18) {

                    Text("CHARACTER STATS")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)

                    DisciplineRadarChart(
                        stats: viewModel.radarValues(for: game.stats)
                    )
                    .frame(height: 240)

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background { surfaceFill }
                .overlay(surfaceBorder)

                VStack(alignment: .leading, spacing: 14) {

                    Text("TITLES")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)

                    ForEach(game.titles, id: \.self) { title in
                        HStack(spacing: 12) {
                            Image(systemName: "seal.fill")
                                .foregroundStyle(viewModel.levelColor(for: game.level))
                            Text(title)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.72))
                        )
                    }

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background { surfaceFill }
                .overlay(surfaceBorder)

            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Ascension")
        .navigationBarTitleDisplayMode(.large)

    }

    private var surfaceFill: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white.opacity(0.88))
    }

    private var surfaceBorder: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
    }

    private func summaryChip(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(tint.opacity(0.75))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(tint.opacity(0.12))
        )
    }

}
