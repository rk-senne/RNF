import SwiftUI

/// P24-RET-24: League tier display with current position and promotion/demotion zone highlighting.
struct LeagueView: View {

    @EnvironmentObject private var gameState: GameState

    @State private var currentTier: LeagueTier = .iron
    @State private var position: Int = 12
    @State private var totalParticipants: Int = 30
    @State private var weeklyXP: Int = 420
    @State private var leagueEntries: [LeagueParticipant] = LeagueParticipant.sampleData

    var body: some View {
        ScrollView {
            VStack(spacing: RNFSpacing.sectionSpacing) {
                tierHeader

                positionCard

                zoneIndicator

                participantList
            }
            .padding(.horizontal, RNFSpacing.md)
            .padding(.vertical, RNFSpacing.md)
        }
        .navigationTitle("League")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Tier Header

    private var tierHeader: some View {
        VStack(spacing: RNFSpacing.sm) {
            Image(systemName: currentTier.iconName)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(currentTier.color)

            Text(currentTier.displayName)
                .font(RNFFont.cardTitle)
                .foregroundStyle(RNFColors.textPrimary)

            Text("Season 1 • Week 4")
                .font(RNFFont.caption)
                .foregroundStyle(RNFColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RNFSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                .fill(currentTier.color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                .strokeBorder(currentTier.color.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Position Card

    private var positionCard: some View {
        HStack(spacing: RNFSpacing.lg) {
            VStack(spacing: 4) {
                Text("#\(position)")
                    .font(RNFFont.display)
                    .foregroundStyle(RNFColors.textPrimary)
                Text("Position")
                    .font(RNFFont.captionSmall)
                    .foregroundStyle(RNFColors.textSecondary)
            }

            Divider()
                .frame(height: 40)

            VStack(spacing: 4) {
                Text("\(weeklyXP)")
                    .font(RNFFont.cardTitle)
                    .foregroundStyle(RNFColors.primary)
                Text("Weekly XP")
                    .font(RNFFont.captionSmall)
                    .foregroundStyle(RNFColors.textSecondary)
            }

            Divider()
                .frame(height: 40)

            VStack(spacing: 4) {
                Text("\(totalParticipants)")
                    .font(RNFFont.cardTitle)
                    .foregroundStyle(RNFColors.textSecondary)
                Text("Players")
                    .font(RNFFont.captionSmall)
                    .foregroundStyle(RNFColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(RNFSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous)
                .fill(RNFColors.surface)
        )
    }

    // MARK: - Zone Indicator

    private var zoneIndicator: some View {
        VStack(spacing: RNFSpacing.sm) {
            HStack {
                zoneLabel(icon: "arrow.up.circle.fill", text: "Promotion Zone", color: .green, range: "Top 5")
                Spacer()
                zoneLabel(icon: "arrow.down.circle.fill", text: "Demotion Zone", color: .red, range: "Bottom 5")
            }

            // Visual bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))

                    // Promotion zone (green, left)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green.opacity(0.3))
                        .frame(width: geo.size.width * promotionFraction)

                    // Demotion zone (red, right)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red.opacity(0.3))
                        .frame(width: geo.size.width * demotionFraction)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    // Current position marker
                    Circle()
                        .fill(RNFColors.primary)
                        .frame(width: 12, height: 12)
                        .offset(x: positionOffset(in: geo.size.width))
                }
            }
            .frame(height: 12)

            HStack {
                Text(currentZoneText)
                    .font(RNFFont.captionBold)
                    .foregroundStyle(currentZoneColor)
                Spacer()
            }
        }
        .padding(RNFSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous)
                .fill(RNFColors.surface)
        )
    }

    // MARK: - Participant List

    private var participantList: some View {
        VStack(spacing: 0) {
            ForEach(Array(leagueEntries.enumerated()), id: \.element.id) { index, participant in
                participantRow(participant, rank: index + 1)

                if index < leagueEntries.count - 1 {
                    Divider()
                        .padding(.leading, 48)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous)
                .fill(RNFColors.surface)
        )
    }

    private func participantRow(_ participant: LeagueParticipant, rank: Int) -> some View {
        HStack(spacing: RNFSpacing.sm) {
            Text("#\(rank)")
                .font(RNFFont.bodyBold)
                .frame(width: 36)
                .foregroundStyle(rankColor(rank))

            Circle()
                .fill(RNFColors.primary.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(participant.displayName.prefix(1)))
                        .font(RNFFont.captionBold)
                        .foregroundStyle(RNFColors.primary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(participant.displayName)
                    .font(participant.isCurrentUser ? RNFFont.bodyBold : RNFFont.body)
                    .foregroundStyle(RNFColors.textPrimary)
                Text("Level \(participant.level)")
                    .font(RNFFont.captionSmall)
                    .foregroundStyle(RNFColors.textSecondary)
            }

            Spacer()

            Text("\(participant.weeklyXP) XP")
                .font(RNFFont.caption)
                .foregroundStyle(RNFColors.textSecondary)
        }
        .padding(.horizontal, RNFSpacing.md)
        .padding(.vertical, RNFSpacing.sm)
        .background(participant.isCurrentUser ? RNFColors.primary.opacity(0.05) : Color.clear)
    }

    // MARK: - Helpers

    private var promotionFraction: CGFloat {
        guard totalParticipants > 0 else { return 0 }
        return CGFloat(5) / CGFloat(totalParticipants)
    }

    private var demotionFraction: CGFloat {
        guard totalParticipants > 0 else { return 0 }
        return CGFloat(5) / CGFloat(totalParticipants)
    }

    private func positionOffset(in width: CGFloat) -> CGFloat {
        guard totalParticipants > 0 else { return 0 }
        let fraction = CGFloat(position - 1) / CGFloat(totalParticipants - 1)
        return (width - 12) * fraction
    }

    private var currentZoneText: String {
        if position <= 5 {
            return "🟢 Promotion Zone — Keep it up!"
        } else if position > totalParticipants - 5 {
            return "🔴 Demotion Zone — Push harder!"
        } else {
            return "⚪ Safe Zone"
        }
    }

    private var currentZoneColor: Color {
        if position <= 5 { return .green }
        if position > totalParticipants - 5 { return .red }
        return RNFColors.textSecondary
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.8)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return RNFColors.textSecondary
        }
    }

    private func zoneLabel(icon: String, text: String, color: Color, range: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
            Text(text)
                .font(RNFFont.captionSmall)
                .foregroundStyle(RNFColors.textSecondary)
            Text("(\(range))")
                .font(RNFFont.captionSmall)
                .foregroundStyle(color)
        }
    }
}

// MARK: - League Tier

enum LeagueTier: String, CaseIterable {
    case iron, bronze, silver, gold, platinum, diamond, legend

    var displayName: String {
        rawValue.capitalized
    }

    var iconName: String {
        switch self {
        case .iron: return "shield.fill"
        case .bronze: return "shield.lefthalf.filled"
        case .silver: return "star.circle.fill"
        case .gold: return "crown.fill"
        case .platinum: return "sparkles"
        case .diamond: return "diamond.fill"
        case .legend: return "bolt.shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .iron: return Color(red: 0.5, green: 0.5, blue: 0.55)
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.8)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum: return Color(red: 0.4, green: 0.8, blue: 0.9)
        case .diamond: return Color(red: 0.6, green: 0.4, blue: 1.0)
        case .legend: return Color(red: 1.0, green: 0.3, blue: 0.3)
        }
    }
}

// MARK: - League Participant Model

struct LeagueParticipant: Identifiable {
    let id = UUID()
    let displayName: String
    let level: Int
    let weeklyXP: Int
    let isCurrentUser: Bool

    static let sampleData: [LeagueParticipant] = [
        .init(displayName: "IronForge99", level: 14, weeklyXP: 820, isCurrentUser: false),
        .init(displayName: "NightOwl", level: 11, weeklyXP: 710, isCurrentUser: false),
        .init(displayName: "MorningRiser", level: 9, weeklyXP: 650, isCurrentUser: false),
        .init(displayName: "You", level: 8, weeklyXP: 420, isCurrentUser: true),
        .init(displayName: "Novice42", level: 6, weeklyXP: 310, isCurrentUser: false),
    ]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LeagueView()
            .environmentObject(GameState())
    }
}
