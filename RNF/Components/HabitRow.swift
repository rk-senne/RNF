import SwiftUI

struct HabitRow: View {

    let habit: Habit
    let completed: Bool
    let animated: Bool
    let action: () -> Void

    var body: some View {

        Button(action: action) {

            VStack(alignment: .leading, spacing: 4) {

                Text(habit.name)
                    .font(.headline)

                Text(habit.description ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)

            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)

            .background(
                completed
                ? Color.yellow.opacity(0.5)
                : Color(.systemGray6)
            )

            .scaleEffect(animated ? 1.05 : 1)
            .animation(.easeOut(duration: 0.25), value: animated)

            .overlay(
                Group {
                    if completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                            .transition(.scale)
                    }
                },
                alignment: .trailing
            )

            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(completed)
    }
}
