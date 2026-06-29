import SwiftUI

struct ImportedWorkoutReviewView: View {
    let workouts: [HealthWorkoutSummary]
    var onAccept: ((HealthWorkoutSummary) -> Void)?

    var body: some View {
        List(workouts) { workout in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.workoutType)
                        .font(RNFFont.statValue)
                    Text("\(workout.durationSeconds / 60) min")
                        .font(RNFFont.caption)
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
