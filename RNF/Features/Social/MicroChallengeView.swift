import SwiftUI

/// P24-GRO-11: Micro-challenge comparison card showing both users' daily completions.
struct MicroChallengeView: View {

    @EnvironmentObject private var gameState: GameState

    let challenge: MicroChallenge

    var body: some View {
        VStack(spacing: RNFSpacing.md) {
            headerSection

            comparisonCard

            statusBadge

            if challenge.status == .active {
                actionButton
            }
        }
        .padding(RNFSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                .fill(RNFColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                .strokeBorder(RNFColors.borderSubtle, lineWidth: 1)
        )
        .rnfShadow(.card)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: RNFSpacing.xs) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(RNFColors.warning)

                Text("MICRO CHALLENGE")
                    .overlineStyle()

                Spacer()

                Text(timeRemaining)
                    .font(RNFFont.captionBold)
                    .foregroundStyle(RNFColors.textSecondary)
            }

            Text(challenge.title)
                .font(RNFFont.section)
                .foregroundStyle(RNFColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Comparison Card

    private var comparisonCard: some View {
        HStack(spacing: 0) {
            // Current user
            playerColumn(
                name: "You",
                completions: challenge.userCompletions,
                target: challenge.targetCompletions,
                color: RNFColors.primary,
                isLeading: challenge.userCompletions >= challenge.opponentCompletions
            )

            // VS divider
            VStack {
                Text("VS")
                    .font(RNFFont.captionBold)
                    .foregroundStyle(RNFColors.textTertiary)
            }
            .frame(width: 44)

            // Opponent
            playerColumn(
                name: challenge.opponentName,
                completions: challenge.opponentCompletions,
                target: challenge.targetCompletions,
                color: RNFColors.warning,
                isLeading: challenge.opponentCompletions > challenge.userCompletions
            )
        }
        .padding(RNFSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }

    private func playerColumn(name: String, completions: Int, target: Int, color: Color, isLeading: Bool) -> some View {
        VStack(spacing: RNFSpacing.sm) {
            // Avatar placeholder
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(name.prefix(1)).uppercased())
                        .font(RNFFont.bodyBold)
                        .foregroundStyle(color)
                )

            Text(name)
                .font(RNFFont.captionBold)
                .foregroundStyle(RNFColors.textPrimary)
                .lineLimit(1)

            // Progress
            Text("\(completions)/\(target)")
                .font(RNFFont.cardTitle)
                .foregroundStyle(color)

            // Progress bar
            ProgressView(value: Double(completions), total: Double(max(target, 1)))
                .tint(color)

            if isLeading && completions > 0 {
                Text("Leading")
                    .font(RNFFont.captionSmall)
                    .foregroundStyle(RNFColors.success)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(RNFFont.caption)
                .foregroundStyle(statusColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button {
            RNFHaptics.buttonTap()
            // TODO: Navigate to habit completion flow
        } label: {
            Text("Complete a Habit")
                .font(RNFFont.bodyBold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: RNFRadius.sm, style: .continuous)
                        .fill(RNFColors.primary)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var timeRemaining: String {
        let remaining = challenge.expiresAt.timeIntervalSinceNow
        guard remaining > 0 else { return "Ended" }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        }
        return "\(minutes)m left"
    }

    private var statusText: String {
        switch challenge.status {
        case .active: return "In Progress"
        case .won: return "You Won! 🎉"
        case .lost: return "Better luck next time"
        case .tied: return "It's a tie!"
        case .pending: return "Waiting for opponent"
        }
    }

    private var statusColor: Color {
        switch challenge.status {
        case .active: return RNFColors.warning
        case .won: return RNFColors.success
        case .lost: return RNFColors.destructive
        case .tied: return RNFColors.textSecondary
        case .pending: return RNFColors.textTertiary
        }
    }
}

// MARK: - MicroChallenge Model

struct MicroChallenge: Identifiable {
    let id: UUID
    let title: String
    let opponentName: String
    let targetCompletions: Int
    var userCompletions: Int
    var opponentCompletions: Int
    let expiresAt: Date
    var status: Status

    enum Status: String {
        case pending
        case active
        case won
        case lost
        case tied
    }

    static let sample = MicroChallenge(
        id: UUID(),
        title: "Most habits today wins!",
        opponentName: "IronForge99",
        targetCompletions: 5,
        userCompletions: 3,
        opponentCompletions: 2,
        expiresAt: Date().addingTimeInterval(3600 * 4),
        status: .active
    )
}

// MARK: - Preview

#Preview {
    VStack {
        MicroChallengeView(challenge: .sample)
            .padding()
    }
    .environmentObject(GameState())
}
