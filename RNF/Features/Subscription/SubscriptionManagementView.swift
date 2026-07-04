import StoreKit
import SwiftUI

/// P23-MON-16: Settings view with plan details, restoration flow,
/// and cancel navigation. This is the dedicated Subscription feature view
/// (the Profile folder retains its existing implementation for backward compatibility).
struct SubscriptionSettingsView: View {

    @EnvironmentObject private var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    private let subscriptionService: SubscriptionService

    @State private var entitlement: SubscriptionEntitlement?
    @State private var products: [Product] = []
    @State private var isLoading = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?
    @State private var showPaywall = false
    @State private var errorMessage: String?

    init(subscriptionService: SubscriptionService = SubscriptionService()) {
        self.subscriptionService = subscriptionService
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RNFSpacing.sectionSpacing) {
                planStatusSection
                featuresSection
                actionsSection
                cancelSection
            }
            .padding(RNFSpacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadState()
        }
        .sheet(isPresented: $showPaywall) {
            RNFPaywallView()
        }
    }

    // MARK: - Plan Status

    private var planStatusSection: some View {
        VStack(alignment: .leading, spacing: RNFSpacing.cardSpacing) {
            Text("CURRENT PLAN")
                .overlineStyle()

            HStack(spacing: RNFSpacing.cardSpacing) {
                statusIcon

                VStack(alignment: .leading, spacing: RNFSpacing.xs) {
                    Text(planTitle)
                        .font(RNFFont.section)
                        .foregroundStyle(RNFColors.textPrimary)

                    Text(planDetail)
                        .font(RNFFont.caption)
                        .foregroundStyle(RNFColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(RNFSpacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                    .fill(RNFColors.surface)
            )
        }
    }

    private var statusIcon: some View {
        Image(systemName: entitlement != nil ? "checkmark.seal.fill" : "lock.open.fill")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(entitlement != nil ? RNFColors.success : RNFColors.primary)
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill((entitlement != nil ? RNFColors.success : RNFColors.primary).opacity(0.12))
            )
            .accessibilityHidden(true)
    }

    private var planTitle: String {
        entitlement != nil ? "Pro Access" : "Free Plan"
    }

    private var planDetail: String {
        guard let entitlement else {
            return "Upgrade to unlock unlimited habits, auto-freezes, and more."
        }
        if let expiry = entitlement.expirationDate {
            return "Renews \(expiry.formatted(date: .abbreviated, time: .omitted))"
        }
        return "Lifetime access — never expires."
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: RNFSpacing.cardSpacing) {
            Text("YOUR FEATURES")
                .overlineStyle()

            VStack(spacing: RNFSpacing.sm) {
                featureStatusRow("Unlimited Habits", unlocked: entitlement != nil)
                featureStatusRow("Skill Tree", unlocked: entitlement != nil)
                featureStatusRow("Auto Streak Freeze", unlocked: entitlement != nil)
                featureStatusRow("Weekly Insights", unlocked: entitlement != nil)
                featureStatusRow("Boss Battles", unlocked: entitlement != nil)
                featureStatusRow("Data Export", unlocked: entitlement != nil)
            }
            .padding(RNFSpacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                    .fill(RNFColors.surface)
            )
        }
    }

    private func featureStatusRow(_ title: String, unlocked: Bool) -> some View {
        HStack(spacing: RNFSpacing.sm) {
            Image(systemName: unlocked ? "checkmark.circle.fill" : "lock.circle")
                .font(.body)
                .foregroundStyle(unlocked ? RNFColors.success : RNFColors.textTertiary)
                .accessibilityLabel(unlocked ? "Unlocked" : "Locked")

            Text(title)
                .font(RNFFont.body)
                .foregroundStyle(unlocked ? RNFColors.textPrimary : RNFColors.textTertiary)

            Spacer()
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: RNFSpacing.cardSpacing) {
            if entitlement == nil {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Upgrade to Pro")
                            .font(RNFFont.bodySemibold)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(RNFColors.primary)
            }

            Button {
                Task { await restorePurchases() }
            } label: {
                HStack {
                    Spacer()
                    Label(
                        isRestoring ? "Restoring…" : "Restore Purchases",
                        systemImage: "arrow.clockwise"
                    )
                    .font(RNFFont.body)
                    Spacer()
                }
            }
            .buttonStyle(.bordered)
            .disabled(isRestoring)

            if let restoreMessage {
                Text(restoreMessage)
                    .font(RNFFont.caption)
                    .foregroundStyle(RNFColors.textSecondary)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(RNFFont.caption)
                    .foregroundStyle(RNFColors.destructive)
            }
        }
    }

    // MARK: - Cancel / Manage

    private var cancelSection: some View {
        VStack(alignment: .leading, spacing: RNFSpacing.cardSpacing) {
            Text("MANAGE")
                .overlineStyle()

            if entitlement != nil {
                Button {
                    openSubscriptionManagement()
                } label: {
                    HStack {
                        Label("Manage in Settings", systemImage: "gear")
                            .font(RNFFont.body)
                            .foregroundStyle(RNFColors.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(RNFColors.textTertiary)
                    }
                }

                Text("Cancel or change your plan via iOS Settings → Subscriptions.")
                    .font(RNFFont.caption)
                    .foregroundStyle(RNFColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No active subscription to manage.")
                    .font(RNFFont.caption)
                    .foregroundStyle(RNFColors.textSecondary)
            }
        }
        .padding(RNFSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                .fill(RNFColors.surface)
        )
    }

    // MARK: - Data Loading

    private func loadState() async {
        isLoading = true
        errorMessage = nil

        do {
            async let fetchedProducts = subscriptionService.fetchProducts()
            async let activeEntitlement = subscriptionService.validateEntitlement()

            products = try await fetchedProducts
            entitlement = await activeEntitlement
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "Could not load subscription details."
        }

        isLoading = false
    }

    private func restorePurchases() async {
        isRestoring = true
        restoreMessage = nil

        do {
            try await AppStore.sync()
            entitlement = await subscriptionService.validateEntitlement()
            restoreMessage = entitlement != nil
                ? "Pro access restored successfully."
                : "No active subscription found."
        } catch {
            restoreMessage = "Restore failed. Please try again."
        }

        isRestoring = false
    }

    private func openSubscriptionManagement() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationStack {
        SubscriptionSettingsView()
            .environmentObject(GameState())
    }
}
