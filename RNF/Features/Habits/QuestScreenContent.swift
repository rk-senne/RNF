import SwiftUI

struct QuestScreenContent: View {

    let dailyQuests: [Habit]
    let weeklyQuest: Habit?
    let completedHabitIDs: Set<UUID>
    let animatedHabit: UUID?
    let completeDailyQuest: (Habit) -> Void

    var body: some View {

        VStack(alignment: .leading, spacing: 18) {
            QuestSectionHeader(
                title: "Daily Quests",
                subtitle: "\(dailyQuests.count) active"
            )

            VStack(spacing: 14) {
                ForEach(dailyQuests) { habit in
                    HabitRow(
                        habit: habit,
                        completed: completedHabitIDs.contains(habit.id),
                        animated: animatedHabit == habit.id,
                        action: {
                            completeDailyQuest(habit)
                        }
                    )
                }
            }

            QuestSectionHeader(
                title: "Weekly Habit",
                subtitle: weeklyQuest == nil ? "Unlocks after week 1" : "7 day focus"
            )
            .padding(.top, 6)

            WeeklyQuestCard(habit: weeklyQuest)
        }
        .padding(.bottom, 24)
    }

}

private struct QuestSectionHeader: View {

    let title: String
    let subtitle: String

    var body: some View {

        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(RNFFont.section)
                .foregroundStyle(Color.primary)

            Spacer(minLength: 12)

            Text(subtitle.uppercased())
                .font(RNFFont.pill)
                .foregroundStyle(Color.secondary)
        }
    }

}

private struct WeeklyQuestCard: View {

    let habit: Habit?

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(tint.opacity(0.12))
                        .frame(width: 56, height: 56)

                    Image(systemName: habit == nil ? "lock.fill" : "calendar.badge.clock")
                        .font(RNFFont.iconLabel)
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(habit?.name ?? "Weekly Habit Unlock")
                        .font(RNFFont.section)
                        .foregroundStyle(Color.primary)

                    Text(habit?.description ?? "Keep completing daily quests to unlock a focused 7 day habit.")
                        .font(RNFFont.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                if let habit {
                    Text("+\(habit.xpReward) XP")
                        .font(RNFFont.captionBoldSmall)
                        .foregroundStyle(Color(red: 0.18, green: 0.45, blue: 0.42))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.84, green: 0.96, blue: 0.92))
                        )
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(RNFColors.borderSubtle, lineWidth: 1)
        )
    }

    private var tint: Color {
        habit == nil
        ? Color(red: 0.45, green: 0.45, blue: 0.5)
        : Color(red: 0.16, green: 0.5, blue: 0.45)
    }

}
