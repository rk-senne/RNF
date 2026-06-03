import SwiftUI

struct SkillTreeView: View {

    @EnvironmentObject private var game: GameState
    @State private var activePerks: ActivePerkSummary = .empty
    @State private var isLoadingActivePerks = false
    @State private var activePerkLoadFailed = false

    private let skillTreeService: SkillTreeService

    init(skillTreeService: SkillTreeService = SkillTreeService()) {
        self.skillTreeService = skillTreeService
    }

    private var isUnlocked: Bool {
        SkillTreeSystem.isSkillTreeUnlocked(for: game.profile)
    }

    private var earnedPoints: Int {
        SkillTreeSystem.skillPointsEarned(for: game.profile)
    }

    var body: some View {

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                activePerksSection

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14)
                    ],
                    spacing: 14
                ) {
                    ForEach(SkillTreePath.allCases, id: \.self) { path in
                        SkillTreePathCard(
                            path: path,
                            statValue: SkillTreeSystem.statValue(
                                for: path,
                                in: game.profile
                            ),
                            isUnlocked: isUnlocked
                        )
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Skill Tree")
        .navigationBarTitleDisplayMode(.large)
        .task(id: game.profile.id) {
            await loadActivePerks()
        }
    }

    private var header: some View {

        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("MASTERY PATHS")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(Color.secondary)

                    Text(isUnlocked ? "Choose a path of mastery." : "Unlocks at Level 10.")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 14)

                VStack(alignment: .trailing, spacing: 6) {
                    Text("POINTS")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(Color.secondary)

                    Text("\(earnedPoints)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.31, green: 0.25, blue: 0.72))
                }
            }

            ProgressView(
                value: Double(min(game.level, SkillTreeSystem.unlockLevel)),
                total: Double(SkillTreeSystem.unlockLevel)
            )
            .tint(Color(red: 0.31, green: 0.25, blue: 0.72))
            .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var activePerksSection: some View {

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACTIVE PERKS")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Color.secondary)

                Spacer()

                Text(activePerkStatusText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.secondary)
            }

            if activePerks.effects.isEmpty {
                Text(activePerkEmptyText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 10) {
                    ForEach(activePerks.effects) { effect in
                        ActivePerkRow(effect: effect)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var activePerkStatusText: String {
        if isLoadingActivePerks {
            return "Syncing"
        }

        if activePerkLoadFailed {
            return "Unavailable"
        }

        return "\(activePerks.effects.count)"
    }

    private var activePerkEmptyText: String {
        activePerkLoadFailed ? "Perks unavailable" : "No active perks"
    }

    private func loadActivePerks() async {
        isLoadingActivePerks = true
        activePerkLoadFailed = false

        do {
            activePerks = try await skillTreeService.activePerks(for: game.profile)
        } catch {
            activePerks = .empty
            activePerkLoadFailed = true
        }

        isLoadingActivePerks = false
    }

}

private struct ActivePerkRow: View {

    let effect: PerkEffect

    var body: some View {

        HStack(spacing: 10) {
            Image(systemName: effect.iconName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(red: 0.31, green: 0.25, blue: 0.72))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(effect.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                Text(effect.summaryText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

private struct SkillTreePathCard: View {

    let path: SkillTreePath
    let statValue: Int
    let isUnlocked: Bool

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: path.iconName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(tint)

                Spacer()

                Text("\(statValue)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(path.displayName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)

                Text(isUnlocked ? "Tier 1 ready" : "Locked")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.secondary)
            }

            HStack(spacing: 8) {
                ForEach(SkillTreeTier.allCases, id: \.self) { tier in
                    Circle()
                        .fill(nodeFill(for: tier))
                        .frame(width: 12, height: 12)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 142, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(tint.opacity(isUnlocked ? 0.45 : 0.16), lineWidth: 1)
        )
    }

    private var tint: Color {
        isUnlocked
        ? Color(red: 0.31, green: 0.25, blue: 0.72)
        : Color(red: 0.48, green: 0.48, blue: 0.52)
    }

    private func nodeFill(for tier: SkillTreeTier) -> Color {
        guard isUnlocked, tier == .tier1 else {
            return Color.gray.opacity(0.25)
        }

        return tint
    }

}

private extension PerkEffect {

    var summaryText: String {
        switch effect_type {

        case .xpMultiplier:
            return "+\(value)% XP"

        case .statBonus:
            return "+\(value) \(stat_type?.displayName ?? "Stat")"

        case .questRewardBonus:
            return "+\(value) quest XP"

        case .streakProtection:
            return "\(value) streak protection"
        }
    }

    var iconName: String {
        switch effect_type {

        case .xpMultiplier:
            return "arrow.up.circle.fill"

        case .statBonus:
            return stat_type?.iconName ?? "plus.circle.fill"

        case .questRewardBonus:
            return "gift.fill"

        case .streakProtection:
            return "shield.fill"
        }
    }

}

private extension SkillTreePath {

    var displayName: String {
        rawValue.capitalized
    }

    var iconName: String {
        switch self {

        case .strength:
            return "figure.strengthtraining.traditional"

        case .discipline:
            return "checkmark.seal.fill"

        case .focus:
            return "scope"

        case .energy:
            return "bolt.fill"

        case .wisdom:
            return "book.closed.fill"

        case .mind:
            return "brain.head.profile"

        case .spirit:
            return "sparkles"
        }
    }

}
