import SwiftUI

// MARK: - P22-EMO-02: Welcome Back View

/// Shown when a user returns after absence.
/// Reduces overwhelm: 1-habit goal, hidden calendar, warm narrative.
struct WelcomeBackView: View {

    var daysAway: Int = 3
    var onContinue: () -> Void = {}

    @State private var gradientPulse = false
    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    var body: some View {

        VStack(alignment: .leading, spacing: 24) {

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 12) {
                Text("WELCOME BACK")
                    .overlineStyle()

                Text("The Forge Remembers You")
                    .font(RNFFont.display)
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(narrativeText)
                    .font(RNFFont.sectionMedium)
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Reduced goal card
            VStack(alignment: .leading, spacing: 16) {
                goalRow(
                    icon: "flame.fill",
                    title: "Today's single goal",
                    detail: "Complete just one habit. That's all it takes to re-light the flame."
                )

                goalRow(
                    icon: "eye.slash",
                    title: "Calendar hidden",
                    detail: "No streak pressure. Your history is safe - we just won't show it today."
                )

                goalRow(
                    icon: "heart.fill",
                    title: "No judgement",
                    detail: "Returning is the hardest part. You already did it."
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

            Button(action: {
                RNFHaptics.buttonTap()
                onContinue()
            }) {
                Text("One habit. Let's go.")
                    .font(RNFFont.bodyBold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)

            Spacer(minLength: 24)

        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background {
            ZStack {
                Color(.systemBackground)
                RadialGradient(
                    colors: [RNFColors.streak.opacity(gradientPulse ? 0.10 : 0.04), .clear],
                    center: .bottomLeading,
                    startRadius: 40,
                    endRadius: 280
                )
            }
            .ignoresSafeArea()
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    gradientPulse = true
                }
            }
        }
        .navigationTitle("Welcome Back")
        .navigationBarTitleDisplayMode(.inline)

    }

    // MARK: - Helpers

    private var narrativeText: String {
        if daysAway <= 3 {
            return "A brief pause. The embers are still warm. One habit is all you need to bring the flame back."
        } else if daysAway <= 7 {
            return "You've been away for \(daysAway) days. The Forge waited patiently. Today, we start simple - just one habit."
        } else {
            return "It's been \(daysAway) days. Life happens. What matters is you're here now. Let's start with one small step."
        }
    }

    private func goalRow(icon: String, title: String, detail: String) -> some View {
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
        WelcomeBackView(daysAway: 5)
    }
}
