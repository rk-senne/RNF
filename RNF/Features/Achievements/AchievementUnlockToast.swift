import SwiftUI

struct AchievementUnlockToast: View {
    let achievement: Achievement
    @Binding var isPresented: Bool

    var body: some View {
        if isPresented {
            VStack(spacing: 8) {
                Image(systemName: achievement.iconName)
                    .font(.system(size: 32))
                    .foregroundStyle(.yellow)
                Text("Achievement Unlocked!")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(achievement.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial))
            .shadow(radius: 10)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { isPresented = false }
            }
        }
    }
}
