import SwiftUI

// P27-LIF-12: Rebirth Confirmation View
// 3-step safety flow showing what resets vs what's kept.
// Step 1: Overview of what rebirth means
// Step 2: Detailed breakdown of preserved vs reset items
// Step 3: Final confirmation with countdown

struct RebirthConfirmationView: View {

    @ObservedObject var prestigeService: PrestigeService
    let preview: PrestigeService.RebirthPreview
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var currentStep: Int = 1
    @State private var confirmationText: String = ""

    private let requiredConfirmation = "REBIRTH"

    var body: some View {
        NavigationStack {
            VStack(spacing: RNFSpacing.lg) {
                // Step indicator
                stepIndicator

                Spacer()

                // Step content
                switch currentStep {
                case 1: stepOneOverview
                case 2: stepTwoDetails
                case 3: stepThreeConfirm
                default: EmptyView()
                }

                Spacer()

                // Navigation buttons
                navigationButtons
            }
            .padding(RNFSpacing.lg)
            .navigationTitle("Rebirth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: RNFSpacing.sm) {
            ForEach(1...3, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.orange : Color.secondary.opacity(0.3))
                    .frame(width: 10, height: 10)

                if step < 3 {
                    Rectangle()
                        .fill(step < currentStep ? Color.orange : Color.secondary.opacity(0.3))
                        .frame(height: 2)
                }
            }
        }
        .padding(.horizontal, RNFSpacing.xl)
    }

    // MARK: - Step 1: Overview

    private var stepOneOverview: some View {
        VStack(spacing: RNFSpacing.lg) {
            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Begin Again, Stronger")
                .font(RNFFont.title)
                .multilineTextAlignment(.center)

            Text("Rebirth resets your progress but grants permanent bonuses that carry across all future journeys.")
                .font(RNFFont.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: RNFSpacing.sm) {
                bonusRow(icon: "arrow.up.right", text: "+\(preview.xpBonusPercent)% XP permanently")
                if preview.startingStatBonus > 0 {
                    bonusRow(icon: "star.fill", text: "+\(preview.startingStatBonus) starting stats")
                }
                bonusRow(icon: "number", text: "Rebirth #\(prestigeService.rebirthCount + 1)")
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: RNFRadius.md).fill(.green.opacity(0.1)))
        }
    }

    // MARK: - Step 2: Details

    private var stepTwoDetails: some View {
        VStack(spacing: RNFSpacing.lg) {
            Text("What Changes?")
                .font(RNFFont.title2)

            // What resets
            VStack(alignment: .leading, spacing: RNFSpacing.sm) {
                Label("Resets", systemImage: "arrow.counterclockwise")
                    .font(RNFFont.headline)
                    .foregroundStyle(.red)

                resetRow("Level → 1")
                resetRow("XP → 0")
                resetRow("Stats → Baseline + bonus")
                resetRow("Chapter progress")
                resetRow("Streak counter")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: RNFRadius.md).fill(.red.opacity(0.05)))

            // What's preserved
            VStack(alignment: .leading, spacing: RNFSpacing.sm) {
                Label("Preserved", systemImage: "lock.shield.fill")
                    .font(RNFFont.headline)
                    .foregroundStyle(.green)

                preserveRow("Titles (\(preview.preservedTitles.count))")
                preserveRow("Achievements (\(preview.preservedAchievements.count))")
                preserveRow("Forge Tokens (\(preview.preservedTokens))")
                preserveRow("Rebirth history & bonuses")
                preserveRow("Legacy milestones")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: RNFRadius.md).fill(.green.opacity(0.05)))
        }
    }

    // MARK: - Step 3: Final Confirm

    private var stepThreeConfirm: some View {
        VStack(spacing: RNFSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)

            Text("This cannot be undone")
                .font(RNFFont.title2)
                .foregroundStyle(.primary)

            Text("Type REBIRTH to confirm")
                .font(RNFFont.body)
                .foregroundStyle(.secondary)

            TextField("Type REBIRTH", text: $confirmationText)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .padding(.horizontal, RNFSpacing.xl)
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: RNFSpacing.md) {
            if currentStep > 1 {
                Button("Back") {
                    withAnimation { currentStep -= 1 }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if currentStep < 3 {
                Button("Next") {
                    withAnimation { currentStep += 1 }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            } else {
                Button("Confirm Rebirth") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(confirmationText != requiredConfirmation)
            }
        }
    }

    // MARK: - Row Helpers

    private func bonusRow(icon: String, text: String) -> some View {
        HStack(spacing: RNFSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 20)
            Text(text)
                .font(RNFFont.body)
        }
    }

    private func resetRow(_ text: String) -> some View {
        HStack(spacing: RNFSpacing.sm) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red.opacity(0.7))
                .font(.caption)
            Text(text)
                .font(RNFFont.subheadline)
        }
    }

    private func preserveRow(_ text: String) -> some View {
        HStack(spacing: RNFSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green.opacity(0.7))
                .font(.caption)
            Text(text)
                .font(RNFFont.subheadline)
        }
    }
}

#Preview {
    let service = PrestigeService()
    let preview = service.generatePreview(
        currentTitles: ["Forged", "Specialist"],
        currentAchievements: ["streak_30", "level_10"],
        currentTokenBalance: 150
    )
    RebirthConfirmationView(
        prestigeService: service,
        preview: preview,
        onConfirm: {},
        onCancel: {}
    )
}
