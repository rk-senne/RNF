import SwiftUI

/// P25-INT-09: Banner UI for dynamic daily goal adjustment suggestions.
/// Shown when DifficultyAdvisor determines user should increase or decrease their goal.
struct DifficultyBanner: View {
    enum Direction {
        case increase
        case decrease
    }

    let direction: Direction
    let currentGoal: Int
    let suggestedGoal: Int
    var onAccept: () -> Void
    var onDismiss: () -> Void

    private var icon: String {
        switch direction {
        case .increase: return "flame.fill"
        case .decrease: return "leaf.fill"
        }
    }

    private var accentColor: Color {
        switch direction {
        case .increase: return RNFColors.primary
        case .decrease: return RNFColors.success
        }
    }

    private var headline: String {
        switch direction {
        case .increase:
            return "The Forge sees your strength"
        case .decrease:
            return "Quality over quantity"
        }
    }

    private var subtitle: String {
        switch direction {
        case .increase:
            return "Ready for more? Move your daily goal from \(currentGoal) to \(suggestedGoal)."
        case .decrease:
            return "Master these first. Adjust your daily goal from \(currentGoal) to \(suggestedGoal)."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: RNFSpacing.sm) {
            HStack(spacing: RNFSpacing.sm) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(accentColor)

                Text(headline)
                    .font(RNFFont.section)
                    .foregroundStyle(RNFColors.textPrimary)
            }

            Text(subtitle)
                .font(RNFFont.body)
                .foregroundStyle(RNFColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: RNFSpacing.md) {
                Button(action: onAccept) {
                    Text("Accept")
                        .font(RNFFont.bodySemibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(accentColor, in: RoundedRectangle(cornerRadius: RNFRadius.sm, style: .continuous))
                }
                .accessibilityLabel("Accept goal adjustment to \(suggestedGoal)")

                Button(action: onDismiss) {
                    Text("Not now")
                        .font(RNFFont.bodySemibold)
                        .foregroundStyle(RNFColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RNFColors.surface, in: RoundedRectangle(cornerRadius: RNFRadius.sm, style: .continuous))
                }
                .accessibilityLabel("Dismiss goal suggestion")
            }
        }
        .padding(RNFSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        )
        .padding(.horizontal, RNFSpacing.md)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Goal adjustment suggestion: \(headline). \(subtitle)")
    }
}

#Preview("Increase") {
    DifficultyBanner(
        direction: .increase,
        currentGoal: 3,
        suggestedGoal: 4,
        onAccept: {},
        onDismiss: {}
    )
    .padding(.vertical)
}

#Preview("Decrease") {
    DifficultyBanner(
        direction: .decrease,
        currentGoal: 4,
        suggestedGoal: 3,
        onAccept: {},
        onDismiss: {}
    )
    .padding(.vertical)
}
