import SwiftUI

// MARK: - P22-EMO-10: Life Happened View

/// Prompt shown on return after 7+ missed days.
/// Offers retroactive pause to protect streak without penalty.
struct LifeHappenedView: View {

    var missedDays: Int = 7
    var cycleID: String = ""
    var onAcceptPause: () -> Void = {}
    var onDecline: () -> Void = {}

    @State private var isActivating = false
    @State private var pauseActivated = false

    var body: some View {

        VStack(alignment: .leading, spacing: 24) {

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 12) {
                Text("LIFE HAPPENED")
                    .overlineStyle()

                Text("We Understand")
                    .font(RNFFont.display)
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("You've been away for \(missedDays) days. Sometimes life demands your full attention - and that's okay. The Forge doesn't punish life.")
                    .font(RNFFont.sectionMedium)
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Retroactive pause offer
            VStack(alignment: .leading, spacing: 16) {
                pauseRow(
                    icon: "pause.circle.fill",
                    title: "Retroactive Pause",
                    detail: "We'll mark the last \(clampedDays) days as a planned pause. Your streak stays protected, no penalties applied."
                )

                pauseRow(
                    icon: "info.circle",
                    title: "One per cycle",
                    detail: "You get one pause per challenge cycle (up to 14 days). Use it wisely."
                )
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )

            VStack(spacing: 12) {
                Button(action: {
                    activateRetroactivePause()
                }) {
                    HStack(spacing: 10) {
                        if isActivating {
                            ProgressView()
                                .controlSize(.small)
                        }

                        Text(pauseActivated ? "Pause Applied" : "Apply Retroactive Pause")
                            .font(RNFFont.bodyBold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isActivating || pauseActivated)

                Button(action: {
                    onDecline()
                }) {
                    Text("No thanks, I'll accept the reset")
                        .font(RNFFont.body)
                        .foregroundStyle(Color.secondary)
                }
                .disabled(isActivating)
            }

            Spacer(minLength: 24)

        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .navigationTitle("Life Happened")
        .navigationBarTitleDisplayMode(.inline)

    }

    // MARK: - Helpers

    private var clampedDays: Int {
        min(missedDays, 14)
    }

    private func activateRetroactivePause() {
        isActivating = true

        let result = PauseService.activateRetroactive(missedDays: missedDays, cycleID: cycleID)

        isActivating = false

        if result != nil {
            pauseActivated = true
            RNFHaptics.buttonTap()
            onAcceptPause()
        } else {
            RNFLogger.log("LifeHappenedView: Failed to activate retroactive pause.")
        }
    }

    private func pauseRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(RNFFont.iconLabel)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(RNFFont.bodyBold)
                    .foregroundStyle(Color.primary)

                Text(detail)
                    .font(RNFFont.body)
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

}

#Preview {
    NavigationStack {
        LifeHappenedView(missedDays: 10, cycleID: "cycle-1")
    }
}
