import SwiftUI

/// P24-GRO-06: Invite friend view with unique referral code and share action.
/// Displays the user's referral code with copy and share (UIActivityViewController) actions.
struct InviteFriendView: View {

    @EnvironmentObject private var gameState: GameState

    @State private var referralCode: String = ""
    @State private var showingShareSheet = false
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(spacing: RNFSpacing.lg) {
                heroSection

                referralCodeCard

                rewardsSection

                inviteButton
            }
            .padding(.horizontal, RNFSpacing.md)
            .padding(.vertical, RNFSpacing.lg)
        }
        .navigationTitle("Invite Friends")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            generateReferralCode()
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [shareMessage])
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: RNFSpacing.sm) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(RNFColors.primary)

            Text("Forge Together")
                .font(RNFFont.cardTitle)
                .foregroundStyle(RNFColors.textPrimary)

            Text("Invite friends to join your journey. Both of you earn Forge Tokens when they sign up.")
                .font(RNFFont.body)
                .foregroundStyle(RNFColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, RNFSpacing.md)
    }

    // MARK: - Referral Code Card

    private var referralCodeCard: some View {
        VStack(spacing: RNFSpacing.md) {
            Text("YOUR REFERRAL CODE")
                .overlineStyle()

            Text(referralCode)
                .font(RNFFont.titleMedium)
                .foregroundStyle(RNFColors.primary)
                .kerning(2)
                .textSelection(.enabled)

            HStack(spacing: RNFSpacing.md) {
                Button {
                    copyToClipboard()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold))
                        Text(copied ? "Copied!" : "Copy")
                            .font(RNFFont.captionBold)
                    }
                    .foregroundStyle(copied ? RNFColors.success : RNFColors.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill((copied ? RNFColors.success : RNFColors.primary).opacity(0.1))
                    )
                }
                .buttonStyle(.plain)

                Button {
                    showingShareSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Share")
                            .font(RNFFont.captionBold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(RNFColors.primary)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(RNFSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                .fill(RNFColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                .strokeBorder(RNFColors.primary.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Rewards Section

    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: RNFSpacing.sm) {
            Text("REWARDS")
                .overlineStyle()

            rewardRow(icon: "flame.fill", color: RNFColors.warning, text: "You get 50 Forge Tokens per invite")
            rewardRow(icon: "gift.fill", color: RNFColors.success, text: "Friend gets 25 bonus Forge Tokens")
            rewardRow(icon: "trophy.fill", color: RNFColors.primary, text: "Unlock exclusive cosmetics at 5 referrals")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RNFSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous)
                .fill(RNFColors.surface)
        )
    }

    private func rewardRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: RNFSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(text)
                .font(RNFFont.body)
                .foregroundStyle(RNFColors.textPrimary)
        }
    }

    // MARK: - Invite Button

    private var inviteButton: some View {
        Button {
            showingShareSheet = true
            RNFHaptics.buttonTap()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "paperplane.fill")
                Text("Send Invite")
                    .font(RNFFont.bodyBold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous)
                    .fill(RNFColors.primary)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Send invite to a friend")
    }

    // MARK: - Helpers

    private var shareMessage: String {
        "Join me on RNF — the habit-building RPG! Use my code \(referralCode) to get bonus Forge Tokens. 🔥"
    }

    private func generateReferralCode() {
        // Generate from user ID; deterministic per-user code
        let idString = gameState.profile.id.uuidString
        let suffix = String(format: "%04X", abs(idString.hashValue) % 0xFFFF)
        referralCode = "RNF-\(suffix)"
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = referralCode
        RNFHaptics.success()

        withAnimation(.easeInOut(duration: 0.2)) {
            copied = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.2)) {
                copied = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        InviteFriendView()
            .environmentObject(GameState())
    }
}
