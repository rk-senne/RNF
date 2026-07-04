import SwiftUI

/// P23-MON-11: Banner shown from Day 12 of the 14-day trial with
/// loss-aversion messaging referencing the user's streak.
struct TrialExpiryBanner: View {

    @EnvironmentObject private var gameState: GameState

    /// Number of days remaining in the trial (0 = expired).
    let daysRemaining: Int

    /// Action triggered when the user taps the upgrade CTA.
    var onUpgradeTapped: () -> Void

    /// The trial duration in days (default 14).
    static let trialDuration: Int = 14

    /// Day within the trial at which the banner first appears (Day 12 = 3 days left).
    static let bannerAppearsAtDaysRemaining: Int = 3

    var body: some View {
        if shouldShow {
            bannerContent
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction {
                    onUpgradeTapped()
                }
        }
    }

    /// Banner shows when 3 or fewer days remain (Day 12+).
    var shouldShow: Bool {
        daysRemaining <= Self.bannerAppearsAtDaysRemaining && daysRemaining >= 0
    }

    private var bannerContent: some View {
        HStack(spacing: RNFSpacing.cardSpacing) {
            VStack(alignment: .leading, spacing: RNFSpacing.xs) {
                Text(headlineText)
                    .font(RNFFont.bodySemibold)
                    .foregroundStyle(RNFColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(lossAversionMessage)
                    .font(RNFFont.caption)
                    .foregroundStyle(RNFColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: RNFSpacing.sm)

            Button(action: onUpgradeTapped) {
                Text("Upgrade")
                    .font(RNFFont.captionBold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, RNFSpacing.md)
                    .padding(.vertical, RNFSpacing.sm)
                    .background(
                        Capsule()
                            .fill(RNFColors.primary)
                    )
            }
            .accessibilityLabel("Upgrade to Pro")
        }
        .padding(RNFSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous)
                .fill(RNFColors.primary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous)
                .strokeBorder(RNFColors.primary.opacity(0.2), lineWidth: 1)
        )
    }

    private var headlineText: String {
        switch daysRemaining {
        case 0:
            return "Your Pro trial has ended"
        case 1:
            return "Last day of your Pro trial"
        default:
            return "\(daysRemaining) days left of Pro trial"
        }
    }

    private var lossAversionMessage: String {
        let streakText = gameState.streak > 0
            ? "Your \(gameState.streak)-day streak"
            : "Your progress"

        switch daysRemaining {
        case 0:
            return "\(streakText) deserves auto-freeze protection. Upgrade to keep it safe."
        case 1:
            return "Tomorrow your skill tree, multipliers, and auto-freezes pause. \(streakText) is at risk."
        default:
            return "\(streakText) won't have auto-freeze protection after your trial. Keep it safe."
        }
    }

    /// Calculates days remaining from a trial start date.
    static func daysRemaining(from trialStartDate: Date, now: Date = Date()) -> Int {
        let calendar = Calendar.current
        let daysSinceStart = calendar.dateComponents([.day], from: trialStartDate, to: now).day ?? 0
        return max(0, trialDuration - daysSinceStart)
    }
}

#Preview("3 days left") {
    TrialExpiryBanner(daysRemaining: 3, onUpgradeTapped: {})
        .environmentObject(GameState())
        .padding()
}

#Preview("Expired") {
    TrialExpiryBanner(daysRemaining: 0, onUpgradeTapped: {})
        .environmentObject(GameState())
        .padding()
}
