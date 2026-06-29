import SwiftUI

struct FocusTimerView: View {

    @Environment(\.dismiss) private var dismiss

    let sessionType: FocusSessionType

    @State private var remainingSeconds: Int
    @State private var elapsedSeconds = 0
    @State private var isRunning = true
    @State private var isComplete = false

    private static let encouragements = [
        "Depth over speed.",
        "One task. Full attention.",
        "The mind sharpens with stillness."
    ]

    init(sessionType: FocusSessionType) {
        self.sessionType = sessionType
        _remainingSeconds = State(initialValue: sessionType.durationSeconds)
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
        .background(
            LinearGradient(
                colors: [Color(hex: "#1A1A2E"), Color(hex: "#0F0F23")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle(sessionType.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: isRunning) {
            await runTimer()
        }
    }

    // MARK: - Timer Content

    private var timerContent: some View {
        VStack(spacing: 24) {
            Text("FOCUS SESSION")
                .overlineStyle()
                .foregroundStyle(.white.opacity(0.7))

            ZStack {
                CircularProgressRing(progress: progress)
                    .frame(width: 200, height: 200)

                Text(timerText)
                    .font(RNFFont.metric)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }

            Text(encouragement)
                .font(RNFFont.body)
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 12) {
                Button {
                    isRunning.toggle()
                    RNFHaptics.impact(.light)
                } label: {
                    Label(isRunning ? "Pause" : "Resume", systemImage: isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    dismiss()
                } label: {
                    Text("End")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Completion Content

    private var completionContent: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(RNFColors.success)

            Text("Focus Complete")
                .font(RNFFont.title)
                .foregroundStyle(.white)

            Text("+\(sessionType.xp) XP")
                .font(RNFFont.section)
                .foregroundStyle(RNFColors.success)

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

    // MARK: - Helpers

    private var timerText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var progress: Double {
        guard sessionType.durationSeconds > 0 else { return 0 }
        return Double(elapsedSeconds) / Double(sessionType.durationSeconds)
    }

    private var encouragement: String {
        Self.encouragements[elapsedSeconds / 60 % Self.encouragements.count]
    }

    private func runTimer() async {
        guard isRunning, !isComplete else { return }

        while isRunning && remainingSeconds > 0 && !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard isRunning, remainingSeconds > 0, !Task.isCancelled else { return }
            remainingSeconds -= 1
            elapsedSeconds += 1
        }

        if remainingSeconds == 0 {
            isRunning = false
            isComplete = true
            RNFHaptics.success()
        }
    }
}

#Preview {
    NavigationStack {
        FocusTimerView(sessionType: .standard)
    }
}
