import SwiftUI

struct AchievementsGalleryView: View {
    let achievements: [Achievement]
    let unlockedIds: Set<String>

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                ForEach(achievements, id: \.id) { achievement in
                    AchievementCard(achievement: achievement, isUnlocked: unlockedIds.contains(achievement.id))
                }
            }
            .padding()
        }
        .navigationTitle("Achievements")
    }
}

private struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.iconName)
                .font(.system(size: 28))
                .foregroundStyle(isUnlocked ? .yellow : .gray)
            Text(achievement.name)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .lineLimit(1)
            Text(achievement.description)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(isUnlocked ? Color.yellow.opacity(0.1) : Color(.tertiarySystemBackground)))
        .opacity(isUnlocked ? 1 : 0.5)
        .accessibilityLabel("\(achievement.name), \(isUnlocked ? "unlocked" : "locked")")
    }
}
