import SwiftUI

struct ActiveWorkoutTimerView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var game: GameState

    let title: String
    let durationSeconds: Int
    let xp: Int

    @StateObject private var viewModel: WorkoutViewModel

    init(title: String, durationSeconds: Int, xp: Int) {
        self.title = title
        self.durationSeconds = durationSeconds
        self.xp = xp
        _viewModel = StateObject(
            wrappedValue: WorkoutViewModel(durationSeconds: durationSeconds)
        )
    }

    var body: some View {

        VStack(spacing: 28) {
            Spacer(minLength: 24)

            if viewModel.isComplete {
                completionContent
            } else {
                timerContent
            }

            Spacer(minLength: 24)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.configure(gameState: game)
        }
        .task(id: viewModel.isRunning) {
            await viewModel.runTimer()
        }

    }

    private var timerContent: some View {

        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("ACTIVE WORKOUT")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Color.secondary)

                Text(viewModel.timerText)
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                ProgressView(value: viewModel.progress)
                    .tint(Color(red: 0.3, green: 0.43, blue: 0.86))
                    .scaleEffect(x: 1, y: 1.8, anchor: .center)
            }

            HStack(spacing: 12) {
                Button {
                    viewModel.toggleRunning()
                } label: {
                    Label(
                        viewModel.primaryControlTitle,
                        systemImage: viewModel.primaryControlIcon
                    )
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canToggleTimer || viewModel.isFinalizing)

                Button(role: .destructive) {
                    endSession()
                } label: {
                    Label("End", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isFinalizing)
            }

            if viewModel.isFinalizing {
                ProgressView("Saving workout")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.secondary)
            }

            if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.red)
                        .multilineTextAlignment(.center)

                    Button {
                        retryCompletion()
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Text("+\(xp) XP after 80% completion")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.secondary)
        }

    }

    private var completionContent: some View {

        VStack(spacing: 18) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(Color(red: 0.12, green: 0.54, blue: 0.3))

            Text("Workout Complete")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(Color.primary)

            Text("+\(viewModel.completedXP ?? xp) XP")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.12, green: 0.54, blue: 0.3))

            Button {
                dismiss()
            } label: {
                Label("Done", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }

    }

    private func endSession() {
        Task {
            let didAttemptCompletion = await viewModel.endSession()

            if !didAttemptCompletion {
                dismiss()
            }
        }
    }

    private func retryCompletion() {
        Task {
            await viewModel.retryCompletion()
        }
    }

}

#Preview {
    NavigationStack {
        ActiveWorkoutTimerView(title: "Push-ups", durationSeconds: 120, xp: 15)
            .environmentObject(GameState())
    }
}
