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
                    .overlineStyle()

                Text("The Forge Is Yours")
                    .font(RNFFont.display)
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Ninety days ago, you made a promise. Today, you kept it. The flame is no longer something you carry. It carries you.")
                    .font(RNFFont.sectionMedium)
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
                        .font(RNFFont.bodyBold)
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
        ChallengeCompletionView()
    }
}
