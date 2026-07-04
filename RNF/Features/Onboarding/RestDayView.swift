import SwiftUI

// MARK: - P22-EMO-16: Rest Day View

/// Banner shown when user activates intentional rest.
/// Limited to 1 rest day per 7-day window.
struct RestDayView: View {

    var onDismiss: () -> Void = {}

    @State private var restActivated = false

    private static let lastRestKey = "rnf_last_rest_day"

    var body: some View {

        VStack(alignment: .leading, spacing: 24) {

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 12) {
                Text("INTENTIONAL REST")
                    .overlineStyle()

                Text("Rest Is Part of the Forge")
                    .font(RNFFont.display)
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Even the strongest steel needs to cool. Taking a deliberate rest day is not weakness - it's wisdom.")
                    .font(RNFFont.sectionMedium)
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Info card
            VStack(alignment: .leading, spacing: 16) {
                restInfoRow(
                    icon: "moon.fill",
                    title: "Streak preserved",
                    detail: "Your streak won't break. Rest days are part of the journey."
                )

                restInfoRow(
                    icon: "calendar.badge.clock",
                    title: "1 per week",
                    detail: "You can take one intentional rest day every 7 days."
                )

                restInfoRow(
                    icon: "bolt.heart.fill",
                    title: "Recovery bonus",
                    detail: "Return tomorrow with renewed energy. The Forge rewards balance."
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
                if canActivateRest {
                    Button(action: {
                        activateRestDay()
                    }) {
                        Text(restActivated ? "Rest Day Active" : "Activate Rest Day")
                            .font(RNFFont.bodyBold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(restActivated)
                } else {
                    Text("Rest day already used this week. Next available in \(daysUntilNextRest) day(s).")
                        .font(RNFFont.body)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                Button(action: {
                    onDismiss()
                }) {
                    Text("Not today")
                        .font(RNFFont.body)
                        .foregroundStyle(Color.secondary)
                }
            }

            Spacer(minLength: 24)

        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .navigationTitle("Rest Day")
        .navigationBarTitleDisplayMode(.inline)

    }

    // MARK: - Logic

    private var canActivateRest: Bool {
        guard let lastRest = Self.lastRestDate() else { return true }
        let daysSince = Calendar.current.dateComponents([.day], from: lastRest, to: Date()).day ?? 0
        return daysSince >= 7
    }

    private var daysUntilNextRest: Int {
        guard let lastRest = Self.lastRestDate() else { return 0 }
        let daysSince = Calendar.current.dateComponents([.day], from: lastRest, to: Date()).day ?? 0
        return max(0, 7 - daysSince)
    }

    private func activateRestDay() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.lastRestKey)
        restActivated = true
        RNFHaptics.buttonTap()
    }

    static func lastRestDate() -> Date? {
        let interval = UserDefaults.standard.double(forKey: lastRestKey)
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    /// Public helper: checks if rest day is available this week.
    static func isRestDayAvailable() -> Bool {
        guard let lastRest = lastRestDate() else { return true }
        let daysSince = Calendar.current.dateComponents([.day], from: lastRest, to: Date()).day ?? 0
        return daysSince >= 7
    }

    // MARK: - Subviews

    private func restInfoRow(icon: String, title: String, detail: String) -> some View {
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
        RestDayView()
    }
}
