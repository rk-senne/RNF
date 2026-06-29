import SwiftUI
import WatchConnectivity

struct WatchHabitListView: View {
    @ObservedObject var state: WatchAppState

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "flame.fill").foregroundStyle(.orange)
                    Text("\(state.snapshot.streak) day streak")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                Text("\(state.snapshot.dailyCompleted)/\(state.snapshot.dailyGoal) today")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Section("Habits") {
                ForEach(state.snapshot.habits) { habit in
                    Button {
                        sendCompletion(habitID: habit.id)
                    } label: {
                        HStack {
                            Text(habit.name)
                                .font(.system(size: 14, design: .rounded))
                            Spacer()
                            if habit.completed {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .disabled(habit.completed)
                }
            }
        }
    }

    private func sendCompletion(habitID: UUID) {
        let message = WatchHabitCompletionMessage(
            idempotencyKey: UUID(),
            habitID: habitID,
            completedAt: Date()
        )
        guard let data = try? JSONEncoder().encode(message),
              WCSession.default.isReachable else { return }
        WCSession.default.sendMessageData(data, replyHandler: nil, errorHandler: nil)
    }
}
