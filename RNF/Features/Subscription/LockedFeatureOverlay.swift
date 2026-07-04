import SwiftUI

/// P23-MON-09: Overlay component for locked Pro features with upgrade CTA button.
/// Use as an overlay or ZStack layer on any Pro-gated content.
struct LockedFeatureOverlay: View {

    /// Human-readable name of the locked feature (e.g., "Skill Tree").
    let featureName: String

    /// Optional description explaining the value of the feature.
    var featureDescription: String?

    /// Action triggered when the user taps the upgrade button.
    var onUpgradeTapped: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: RNFSpacing.md) {
                lockIcon

                VStack(spacing: RNFSpacing.sm) {
                    Text("\(featureName) is a Pro feature")
                        .font(RNFFont.section)
                        .foregroundStyle(RNFColors.textPrimary)
                        .multilineTextAlignment(.center)

                    if let featureDescription {
                        Text(featureDescription)
                            .font(RNFFont.body)
                            .foregroundStyle(RNFColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                upgradeButton
            }
            .padding(RNFSpacing.xl)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 20, y: 8)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isModal)
    }

    private var lockIcon: some View {
        Image(systemName: "lock.shield.fill")
            .font(.system(size: 40))
            .foregroundStyle(RNFColors.primary)
            .frame(width: 72, height: 72)
            .background(
                Circle()
                    .fill(RNFColors.primary.opacity(0.1))
            )
            .accessibilityHidden(true)
    }

    private var upgradeButton: some View {
        Button(action: onUpgradeTapped) {
            HStack(spacing: RNFSpacing.sm) {
                Image(systemName: "crown.fill")
                    .font(.subheadline)
                Text("Upgrade to Pro")
                    .font(RNFFont.bodySemibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, RNFSpacing.cardSpacing)
            .background(
                Capsule()
                    .fill(RNFColors.primary)
            )
        }
        .accessibilityLabel("Upgrade to Pro to unlock \(featureName)")
    }
}

// MARK: - View Modifier

extension View {
    /// Applies a locked feature overlay when `isLocked` is true.
    func lockedOverlay(
        isLocked: Bool,
        featureName: String,
        featureDescription: String? = nil,
        onUpgradeTapped: @escaping () -> Void
    ) -> some View {
        self.overlay {
            if isLocked {
                LockedFeatureOverlay(
                    featureName: featureName,
                    featureDescription: featureDescription,
                    onUpgradeTapped: onUpgradeTapped
                )
            }
        }
    }
}

#Preview {
    ZStack {
        VStack {
            Text("Skill Tree Content")
                .font(.largeTitle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))

        LockedFeatureOverlay(
            featureName: "Skill Tree",
            featureDescription: "Unlock branching progression paths to specialize your discipline journey.",
            onUpgradeTapped: {}
        )
    }
}
