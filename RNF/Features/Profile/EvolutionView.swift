import SwiftUI

struct EvolutionView: View {

    @EnvironmentObject private var game: GameState

    var statChanges: [String: Int] = [:]
    private let evolutionService = EvolutionService()

    private var state: EvolutionState {
        evolutionService.evolutionState(for: game.profile)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 18) {

            HStack(alignment: .firstTextBaseline) {
                Text("EVOLUTION")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 12)

                Text(state.currentTier.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(state.currentTier.rank.tint)
            }

            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(state.currentTier.rank.tint.opacity(0.16))
                        .frame(width: 58, height: 58)

                    Image(systemName: state.currentTier.rank.iconName)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(state.currentTier.rank.tint)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(state.currentTier.name)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(state.currentTier.description)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let nextTier = state.nextTier {
                nextTierProgress(nextTier)
            } else {
                apexReached
            }

            if !state.currentTier.rewards.isEmpty {
                rewardGrid
            }

            if !statChanges.isEmpty {
                statChangeList
            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
        )

    }

    private func nextTierProgress(_ nextTier: EvolutionTier) -> some View {

        VStack(alignment: .leading, spacing: 12) {
            Text("NEXT: \(nextTier.name.uppercased())")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(nextTier.rank.tint)

            milestoneRow(
                title: "Level",
                currentValue: game.level,
                requiredValue: nextTier.requiredLevel,
                tint: nextTier.rank.tint
            )

            milestoneRow(
                title: "Streak",
                currentValue: game.streak,
                requiredValue: nextTier.requiredStreak,
                tint: nextTier.rank.tint
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(nextTier.rank.tint.opacity(0.1))
        )

    }

    private func milestoneRow(
        title: String,
        currentValue: Int,
        requiredValue: Int,
        tint: Color
    ) -> some View {

        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer(minLength: 12)

                Text("\(min(currentValue, requiredValue)) / \(requiredValue)")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(tint)
            }

            ProgressView(
                value: Double(min(currentValue, requiredValue)),
                total: Double(max(requiredValue, 1))
            )
            .tint(tint)
        }

    }

    private var apexReached: some View {

        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(EvolutionRank.apex.tint)

            Text("Apex evolution reached.")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(EvolutionRank.apex.tint.opacity(0.1))
        )

    }

    private var rewardGrid: some View {

        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 8
        ) {
            ForEach(state.currentTier.rewards, id: \.self) { reward in
                Text(reward.displayName)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(state.currentTier.rank.tint)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .padding(.horizontal, 10)
                    .background(
                        Capsule()
                            .fill(state.currentTier.rank.tint.opacity(0.12))
                    )
            }
        }

    }

    private var statChangeList: some View {

        VStack(spacing: 12) {
            ForEach(statChanges.keys.sorted(), id: \.self) { stat in
                HStack {
                    Text(stat)
                        .font(.system(size: 15, weight: .bold, design: .rounded))

                    Spacer()

                    Text("+\(statChanges[stat] ?? 0)")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(Color.green)
                }
            }
        }

    }

}

private extension EvolutionRank {

    var tint: Color {
        switch self {

        case .disciple:
            return .yellow

        case .awakened:
            return .purple

        case .ascendant:
            return .red

        case .warlord:
            return .blue

        case .apex:
            return Color(red: 0.66, green: 0.66, blue: 0.72)
        }
    }

    var iconName: String {
        switch self {

        case .disciple:
            return "flame.fill"

        case .awakened:
            return "sparkles"

        case .ascendant:
            return "arrow.up.circle.fill"

        case .warlord:
            return "shield.fill"

        case .apex:
            return "crown.fill"
        }
    }

}

private extension EvolutionReward {

    var displayName: String {
        switch self {

        case .title:
            return "Title"

        case .minorXPBonus:
            return "XP Bonus"

        case .skillTree:
            return "Skill Tree"

        case .advancedQuests:
            return "Advanced Quests"

        case .avatarUpgrade:
            return "Avatar Upgrade"

        case .challengeTypes:
            return "Challenge Types"

        case .profileBadge:
            return "Profile Badge"

        case .specialRecognition:
            return "Recognition"
        }
    }

}
