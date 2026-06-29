import SwiftUI

struct WorkoutListView: View {

    private struct WorkoutOption: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let duration: String
        let durationSeconds: Int
        let xp: Int
    }

    private let quickChallenges = [
        WorkoutOption(
            title: "Push-ups",
            subtitle: "Upper-body strength",
            duration: "2 min",
            durationSeconds: 120,
            xp: 15
        ),
        WorkoutOption(
            title: "Squats",
            subtitle: "Leg power and stamina",
            duration: "2 min",
            durationSeconds: 120,
            xp: 15
        ),
        WorkoutOption(
            title: "Sit-ups",
            subtitle: "Core control",
            duration: "2 min",
            durationSeconds: 120,
            xp: 15
        )
    ]

    private let timedWorkouts = [
        WorkoutOption(title: "1 min", subtitle: "Fast reset", duration: "1 min", durationSeconds: 60, xp: 15),
        WorkoutOption(title: "3 min", subtitle: "Short burn", duration: "3 min", durationSeconds: 180, xp: 15),
        WorkoutOption(title: "5 min", subtitle: "Steady effort", duration: "5 min", durationSeconds: 300, xp: 15),
        WorkoutOption(title: "10 min", subtitle: "Focused session", duration: "10 min", durationSeconds: 600, xp: 15),
        WorkoutOption(title: "15 min", subtitle: "Full commitment", duration: "15 min", durationSeconds: 900, xp: 15)
    ]

    var body: some View {

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("WORKOUTS")
                        .overlineStyle()

                    Text("Build the body that can carry the mission.")
                        .font(RNFFont.section)
                        .foregroundStyle(Color.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)

                quickChallengeSection
                timedWorkoutSection
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Workouts")
        .navigationBarTitleDisplayMode(.large)

    }

    private var quickChallengeSection: some View {

        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Challenges")
                .font(RNFFont.section)
                .foregroundStyle(Color.primary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(quickChallenges) { workout in
                    workoutButton(for: workout, compact: true)
                }
            }
        }

    }

    private var timedWorkoutSection: some View {

        VStack(alignment: .leading, spacing: 12) {
            Text("Timed Workouts")
                .font(RNFFont.section)
                .foregroundStyle(Color.primary)

            VStack(spacing: 12) {
                ForEach(timedWorkouts) { workout in
                    workoutButton(for: workout, compact: false)
                }
            }
        }

    }

    private func workoutButton(for workout: WorkoutOption, compact: Bool) -> some View {

        NavigationLink {
            ActiveWorkoutTimerView(
                title: workout.title,
                durationSeconds: workout.durationSeconds,
                xp: workout.xp
            )
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(workout.title)
                        .font(.system(size: compact ? 16 : 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(workout.subtitle)
                        .font(RNFFont.caption)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        workoutPill(workout.duration, tint: Color(red: 0.3, green: 0.43, blue: 0.86))
                        workoutPill("+\(workout.xp) XP", tint: Color(red: 0.12, green: 0.54, blue: 0.3))
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(RNFFont.captionBold)
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: compact ? 112 : 74, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(RNFColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(RNFCardButtonStyle())

    }

    private func workoutPill(_ text: String, tint: Color) -> some View {

        Text(text)
            .font(RNFFont.pill)
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(tint.opacity(0.12))
            )

    }

}

#Preview {
    NavigationStack {
        WorkoutListView()
    }
}
