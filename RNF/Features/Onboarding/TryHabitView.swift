import SwiftUI

// P22-ONB-02: Allow single habit completion with XP animation before signup.
struct TryHabitView: View {

    @ObservedObject var guestSession: GuestSessionManager

    let onContinue: () -> Void

    @State private var selectedHabit: HabitPreset?
    @State private var showXPGain = false
    @State private var xpOffset: CGFloat = 0
    @State private var xpOpacity: Double = 1.0

    private let sampleHabits: [HabitPreset] = [
        HabitPreset(id: "try_cold_shower", name: "Cold shower", category: .body, stat: "energy", xpReward: 15),
        HabitPreset(id: "try_meditate", name: "Meditate 5 min", category: .mind, stat: "focus", xpReward: 15),
        HabitPreset(id: "try_gratitude", name: "Gratitude list", category: .spirit, stat: "spirit", xpReward: 15),
    ]

    var body: some View {
        VStack(spacing: RNFSpacing.lg) {
            Spacer(minLength: RNFSpacing.xl)

            VStack(spacing: RNFSpacing.sm) {
                Text("TRY IT OUT")
                    .overlineStyle()

                Text("Complete a Habit")
                    .font(RNFFont.title)
                    .foregroundStyle(RNFColors.textPrimary)

                Text("Tap one to feel the XP rush")
                    .font(RNFFont.body)
                    .foregroundStyle(RNFColors.textSecondary)
            }
            .multilineTextAlignment(.center)

            Spacer(minLength: RNFSpacing.md)

            VStack(spacing: RNFSpacing.cardSpacing) {
                ForEach(sampleHabits, id: \.id) { habit in
                    TryHabitRow(
                        habit: habit,
                        isCompleted: guestSession.completedHabitIDs.contains(habit.id),
                        onTap: { completeHabit(habit) }
                    )
                }
            }
            .padding(.horizontal, RNFSpacing.md)

            if showXPGain {
                Text("+15 XP")
                    .font(RNFFont.cardTitle)
                    .foregroundStyle(RNFColors.primary)
                    .offset(y: xpOffset)
                    .opacity(xpOpacity)
            }

            Spacer()

            if !guestSession.completedHabitIDs.isEmpty {
                Button(action: onContinue) {
                    Text("Continue")
                        .font(RNFFont.bodySemibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, RNFSpacing.md)
                        .background(RNFColors.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous))
                }
                .padding(.horizontal, RNFSpacing.md)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer(minLength: RNFSpacing.lg)
        }
        .animationIfAllowed(.spring(response: 0.5, dampingFraction: 0.8), value: guestSession.completedHabitIDs.count)
    }

    private func completeHabit(_ habit: HabitPreset) {
        guard !guestSession.completedHabitIDs.contains(habit.id) else { return }

        selectedHabit = habit
        guestSession.completeHabit(id: habit.id, xpReward: habit.xpReward)

        showXPGain = true
        xpOffset = 0
        xpOpacity = 1.0

        withAnimation(.easeOut(duration: 1.2)) {
            xpOffset = -60
            xpOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            showXPGain = false
        }

        RNFHaptics.success()
    }
}

// MARK: - Habit Row

private struct TryHabitRow: View {

    let habit: HabitPreset
    let isCompleted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: RNFSpacing.md) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? RNFColors.success : RNFColors.textTertiary)

                VStack(alignment: .leading, spacing: RNFSpacing.xxs) {
                    Text(habit.name)
                        .font(RNFFont.bodySemibold)
                        .foregroundStyle(RNFColors.textPrimary)

                    Text("+\(habit.xpReward) XP · \(habit.stat.capitalized)")
                        .font(RNFFont.caption)
                        .foregroundStyle(RNFColors.textSecondary)
                }

                Spacer()

                if isCompleted {
                    Text("Done!")
                        .font(RNFFont.captionBold)
                        .foregroundStyle(RNFColors.success)
                }
            }
            .padding(RNFSpacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous)
                    .fill(isCompleted ? RNFColors.success.opacity(0.08) : RNFColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous)
                    .stroke(isCompleted ? RNFColors.success.opacity(0.3) : RNFColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isCompleted)
        .accessibilityLabel("\(habit.name), \(isCompleted ? "completed" : "tap to complete")")
    }
}
