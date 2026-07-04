import SwiftUI

/// GAP 2: Prompts forgiveness option when daily_progress → missed_day.
/// Spec: RNF_STATE_MACHINE.md — "If a day ends without completing daily goals:
/// Transition: daily_progress → missed_day. System response: Prompt forgiveness option."
struct MissedDayView: View {

    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var gameState: GameState
    @State private var isProcessing = false

    private let challengeEngine = ChallengeEngine()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Color.orange)

            Text("The flame dimmed.")
                .font(RNFFont.title)

            Text("A single missed day does not unmake you. The Forge knows the difference between a stumble and a surrender.")
                .font(RNFFont.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Button {
                    Task { await useForgiveness() }
                } label: {
                    Text("Use Resilience Token")
                        .font(RNFFont.bodyBold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)

                Button {
                    appStateManager.resolveAfterMissedDay()
                } label: {
                    Text("Accept and rebuild.")
                        .font(RNFFont.body)
                        .foregroundStyle(.secondary)
                }
                .disabled(isProcessing)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private func useForgiveness() async {
        isProcessing = true
        defer { isProcessing = false }
        let authProvider: AuthProviding = AuthService()
        guard let userId = await authProvider.currentUserID else { return }
        _ = await challengeEngine.useForgiveness(
            userId: userId,
            currentStreak: gameState.streak
        )
        appStateManager.resolveAfterMissedDay()
    }
}
