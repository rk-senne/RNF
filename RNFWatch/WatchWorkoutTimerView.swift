import SwiftUI
import WatchConnectivity

struct WatchWorkoutTimerView: View {
    let durationSeconds: Int
    @State private var elapsed = 0
    @State private var isRunning = false
    @State private var timer: Timer?

    private var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(Double(elapsed) / Double(durationSeconds), 1)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(timeString(elapsed))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()

            ProgressView(value: progress)
                .tint(.green)

            if elapsed >= Int(Double(durationSeconds) * 0.8) && !isRunning {
                Button("Complete") { sendComplete() }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
            } else {
                Button(isRunning ? "Pause" : "Start") { toggleTimer() }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private func toggleTimer() {
        if isRunning {
            timer?.invalidate()
            timer = nil
        } else {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
                DispatchQueue.main.async {
                    elapsed += 1
                    if elapsed >= durationSeconds { timer?.invalidate(); isRunning = false }
                }
            }
        }
        isRunning.toggle()
    }

    private func sendComplete() {
        let message = WatchWorkoutMessage(idempotencyKey: UUID(), action: .complete, durationSeconds: elapsed)
        guard let data = try? JSONEncoder().encode(message),
              WCSession.default.isReachable else { return }
        WCSession.default.sendMessageData(data, replyHandler: nil, errorHandler: nil)
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
