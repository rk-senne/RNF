import StoreKit
import SwiftUI

/// P23-MON-13/14/15: Paywall view using SubscriptionStoreView showing
/// monthly/yearly/lifetime tiers with current streak display for loss-aversion.
struct RNFPaywallView: View {

    @EnvironmentObject private var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    /// Product IDs matching StoreKit configuration.
    static let groupID = "com.rnf.pro"
    static let productIDs: Set<String> = [
        "com.rnf.pro.monthly",
        "com.rnf.pro.yearly",
        "com.rnf.pro.lifetime"
    ]

    /// Optional context string describing which feature triggered the paywall.
    var triggerFeature: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: RNFSpacing.lg) {
                    streakHeader
                    featurePreviewSection
                    subscriptionStoreSection
                    dismissButton
                }
                .padding(.horizontal, RNFSpacing.md)
                .padding(.vertical, RNFSpacing.lg)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(RNFColors.textTertiary)
                    }
                    .accessibilityLabel("Dismiss")
                }
            }
        }
    }

    // MARK: - Streak Header (Loss Aversion)

    private var streakHeader: some View {
        VStack(spacing: RNFSpacing.sm) {
            Image(systemName: "flame.fill")
                .font(.system(size: 44))
                .foregroundStyle(RNFColors.streak)
                .accessibilityHidden(true)

            Text("Your Streak: \(gameState.streak) days")
                .font(RNFFont.titleMedium)
                .foregroundStyle(RNFColors.textPrimary)

            if gameState.streak >= 7 {
                Text("You've built \(gameState.streak) days of momentum. Protect it.")
                    .font(RNFFont.body)
                    .foregroundStyle(RNFColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, RNFSpacing.md)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Feature Preview

    private var featurePreviewSection: some View {
        VStack(alignment: .leading, spacing: RNFSpacing.cardSpacing) {
            Text("PRO FEATURES")
                .overlineStyle()

            VStack(spacing: RNFSpacing.sm) {
                featureRow(icon: "tree.fill", title: "Skill Tree", desc: "Branching progression paths")
                featureRow(icon: "chart.bar.fill", title: "Weekly Insights", desc: "Detailed analytics & trends")
                featureRow(icon: "shield.checkered", title: "Auto Streak Freeze", desc: "3 auto-freezes per month")
                featureRow(icon: "infinity", title: "Unlimited Habits", desc: "No category or count limits")
                featureRow(icon: "person.3.fill", title: "Boss Battles & Leagues", desc: "Competitive challenges")
            }
        }
        .padding(RNFSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                .fill(RNFColors.surface)
        )
    }

    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: RNFSpacing.cardSpacing) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(RNFColors.primary)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(RNFFont.bodySemibold)
                    .foregroundStyle(RNFColors.textPrimary)
                Text(desc)
                    .font(RNFFont.caption)
                    .foregroundStyle(RNFColors.textSecondary)
            }

            Spacer()

            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundStyle(RNFColors.textTertiary)
                .accessibilityLabel("Locked")
        }
    }

    // MARK: - Subscription Store

    private var subscriptionStoreSection: some View {
        VStack(spacing: RNFSpacing.md) {
            SubscriptionStoreView(groupID: Self.groupID) {
                VStack(spacing: RNFSpacing.sm) {
                    if let triggerFeature {
                        Text("Unlock \(triggerFeature) and more")
                            .font(RNFFont.section)
                            .foregroundStyle(RNFColors.textPrimary)
                    }
                    personalizedValueMessage
                }
            }
            .subscriptionStoreControlStyle(.prominentPicker)
            .storeButton(.visible, for: .restorePurchases)
            .frame(minHeight: 200)
        }
    }

    @ViewBuilder
    private var personalizedValueMessage: some View {
        if gameState.streak >= 14 {
            Text("With Pro, your \(gameState.streak)-day streak would have auto-freeze protection.")
                .font(RNFFont.caption)
                .foregroundStyle(RNFColors.textSecondary)
                .multilineTextAlignment(.center)
        } else if gameState.xp > 0 {
            Text("You've earned \(gameState.xp) XP. Keep your momentum with Pro.")
                .font(RNFFont.caption)
                .foregroundStyle(RNFColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Dismiss

    private var dismissButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Not now")
                .font(RNFFont.body)
                .foregroundStyle(RNFColors.textSecondary)
        }
        .padding(.top, RNFSpacing.sm)
        .accessibilityLabel("Dismiss paywall")
    }
}

#Preview {
    RNFPaywallView(triggerFeature: "Skill Tree")
        .environmentObject(GameState())
}
