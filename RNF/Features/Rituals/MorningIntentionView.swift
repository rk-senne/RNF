import SwiftUI

struct MorningIntentionView: View {

    @EnvironmentObject private var game: GameState
    @EnvironmentObject private var ritualManager: RitualManager
    @State private var selectedStat: String?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Greeting — simple, human
            Text(greeting)
                .font(RNFFont.titleLarge)
                .foregroundStyle(.primary)
                .padding(.bottom, 24)

            // One line of context — not a wall of text
            Text("Day \(game.streak + 1). What deserves your energy today?")
                .font(RNFFont.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 32)

            // Three choices — clear, tappable, immediate understanding
            HStack(spacing: 12) {
                ForEach(focusOptions, id: \.self) { stat in
                    focusButton(stat)
                }
            }
            .padding(.bottom, 40)

            // Quote — subtle, not competing for attention
            Text(QuoteEngine.todayQuote().text)
                .font(.system(size: 13, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 32)

            Spacer()

            // Action — always available, never blocked
            Button {
                RNFHaptics.buttonTap()
                if let stat = selectedStat {
                    ritualManager.setIntention(stat: stat)
                } else {
                    ritualManager.dismissMorning()
                }
            } label: {
                Text(selectedStat != nil ? "Begin" : "Skip")
                    .font(RNFFont.bodyBold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(selectedStat != nil ? RNFColors.primary : .gray)
            .padding(.bottom, 48)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Components

    private func focusButton(_ stat: String) -> some View {
        Button {
            if UIAccessibility.isReduceMotionEnabled {
                selectedStat = selectedStat == stat ? nil : stat
            } else {
                withAnimation(.spring(response: 0.25)) {
                    selectedStat = selectedStat == stat ? nil : stat
                }
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: statIcon(stat))
                    .font(RNFFont.section)
                Text(stat)
                    .font(RNFFont.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .foregroundStyle(selectedStat == stat ? .white : .primary)
            .background(
                RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous)
                    .fill(selectedStat == stat ? RNFColors.primary : RNFColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous)
                    .strokeBorder(selectedStat == stat ? .clear : RNFColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Focus on \(stat)")
    }

    // MARK: - Data

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var focusOptions: [String] {
        let pairs: [(String, Int)] = [
            ("Strength", game.stats.strength), ("Discipline", game.stats.discipline),
            ("Focus", game.stats.focus), ("Energy", game.stats.energy),
            ("Wisdom", game.stats.wisdom), ("Mind", game.stats.mind), ("Spirit", game.stats.spirit)
        ]
        return Array(pairs.sorted { $0.1 < $1.1 }.prefix(3).map(\.0))
    }

    private func statIcon(_ stat: String) -> String {
        switch stat {
        case "Strength": return "bolt.fill"
        case "Discipline": return "shield.fill"
        case "Focus": return "scope"
        case "Energy": return "flame.fill"
        case "Wisdom": return "book.fill"
        case "Mind": return "brain.head.profile"
        case "Spirit": return "sparkles"
        default: return "star.fill"
        }
    }
}
