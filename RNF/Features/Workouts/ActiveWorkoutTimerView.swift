import SwiftUI

struct ActiveWorkoutTimerView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var game: GameState

    let title: String
    let durationSeconds: Int
    let xp: Int

    @State private var remainingSeconds: Int
    @State private var elapsedSeconds = 0
    @State private var isRunning = true
    @State private var isComplete = false

    private let workoutEngine = WorkoutEngine()

    init(title: String, durationSeconds: Int, xp: Int) {
        self.title = title
        self.durationSeconds = durationSeconds
        self.xp = xp
        _remainingSeconds = State(initialValue: durationSeconds)
    }

    var body: some View {

        VStack(spacing: 28) {
            Spacer(minLength: 24)

            if isComplete {
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
            workoutEngine.configure(gameState: game)
        }
        .task(id: isRunning) {
            await runTimer()
        }

    }

    private var timerContent: some View {

        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("ACTIVE WORKOUT")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Color.secondary)

                Text(timerText)
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                ProgressView(value: progress)
                    .tint(Color(red: 0.3, green: 0.43, blue: 0.86))
                    .scaleEffect(x: 1, y: 1.8, anchor: .center)
            }

            HStack(spacing: 12) {
                Button {
                    isRunning.toggle()
                } label: {
                    Label(isRunning ? "Pause" : "Resume", systemImage: isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    endSession()
                } label: {
                    Text("End")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
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

            Text("+\(xp) XP")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.12, green: 0.54, blue: 0.3))

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }

    }

    private var timerText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var progress: Double {
        guard durationSeconds > 0 else {
            return 0
        }

        return Double(elapsedSeconds) / Double(durationSeconds)
    }

    private func runTimer() async {
        guard isRunning, !isComplete else {
            return
        }

        while isRunning && remainingSeconds > 0 && !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            guard isRunning, remainingSeconds > 0, !Task.isCancelled else {
                return
            }

            remainingSeconds -= 1
            elapsedSeconds += 1
        }

        if remainingSeconds == 0 {
            completeSession()
        }
    }

    private func endSession() {
        if WorkoutDurationValidator.isComplete(
            durationSeconds: durationSeconds,
            elapsedSeconds: elapsedSeconds
        ) {
            completeSession()
        } else {
            dismiss()
        }
    }

    private func completeSession() {
        isRunning = false
        isComplete = true

        Task {
            _ = await workoutEngine.completeWorkout(
                durationSeconds: durationSeconds,
                elapsedSeconds: max(elapsedSeconds, durationSeconds)
            )
        }
    }

}

#Preview {
    NavigationStack {
        ActiveWorkoutTimerView(title: "Push-ups", durationSeconds: 120, xp: 15)
            .environmentObject(GameState())
    }
}
