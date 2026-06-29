import SwiftUI

struct ImportedWorkoutReviewView: View {
    let workouts: [HealthWorkoutSummary]
    var onAccept: ((HealthWorkoutSummary) -> Void)?

    var body: some View {
        List(workouts) { workout in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.workoutType)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text("\(workout.durationSeconds / 60) min")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if workout.accepted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button("Accept") { onAccept?(workout) }
                        .buttonStyle(.bordered)
                        .minimumTapTarget()
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.plain)
        .navigationTitle("Import Workouts")
    }
}
