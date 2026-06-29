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

            Text("Day Missed")
                .font(.system(size: 28, weight: .black, design: .rounded))

            Text("Yesterday's goals were not completed. Use a forgiveness token to preserve your streak?")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Button {
                    Task { await useForgiveness() }
                } label: {
                    Text("Use Forgiveness Token")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)

                Button {
                    appStateManager.resolveAfterMissedDay()
                } label: {
                    Text("Continue Without")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
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
        _ = try? await challengeEngine.useForgiveness()
        appStateManager.resolveAfterMissedDay()
    }
}
