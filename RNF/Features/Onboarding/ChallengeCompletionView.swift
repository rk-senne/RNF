import SwiftUI

struct ChallengeCompletionView: View {

    var completedChallenge: Challenge?
    var onRestart: (Challenge) -> Void = { _ in }

    private let challengeEngine = ChallengeEngine()

    @State private var isRestarting = false

    var body: some View {

        VStack(alignment: .leading, spacing: 24) {

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 12) {
                Text("CHALLENGE COMPLETE")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Color.secondary)

                Text("90 Days Complete")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("You finished the transformation arc. Your discipline title is unlocked.")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 16) {
                completionRow(
                    icon: "checkmark.seal.fill",
                    title: "Challenge cleared",
                    detail: "The full 90-day commitment is complete."
                )

                completionRow(
                    icon: "star.circle.fill",
                    title: "Title unlocked",
                    detail: "Your next phase begins from a higher baseline."
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

            Button {
                restartChallenge()
            } label: {
                HStack(spacing: 10) {
                    if isRestarting {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Text(isRestarting ? "Restarting" : "Restart Challenge")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .disabled(completedChallenge == nil || isRestarting)

            Spacer(minLength: 24)

        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .navigationTitle("Complete")
        .navigationBarTitleDisplayMode(.inline)

    }

    private func restartChallenge() {
        guard let completedChallenge else {
            return
        }

        isRestarting = true

        Task {
            let restartedChallenge = await challengeEngine.restartChallenge(completedChallenge)
            isRestarting = false

            guard let restartedChallenge else {
                return
            }

            onRestart(restartedChallenge)
        }
    }

    private func completionRow(icon: String, title: String, detail: String) -> some View {

        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)

                Text(detail)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

    }

}

#Preview {
    NavigationStack {
        ChallengeCompletionView()
    }
}
