import SwiftUI

struct HabitRow: View {

    let habit: Habit
    let completed: Bool
    let animated: Bool
    let action: () -> Void
    private var accentColor: Color {
        completed
        ? Color(red: 0.81, green: 0.67, blue: 0.16)
        : Color(red: 0.17, green: 0.17, blue: 0.2)
    }

    var body: some View {

        Button(action: action) {

            HStack(spacing: 14) {

                ZStack {

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(accentColor.opacity(completed ? 0.16 : 0.08))
                        .frame(width: 56, height: 56)

                    Image(systemName: iconName())
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(accentColor)

                }

                VStack(alignment: .leading, spacing: 6) {

                    Text(habit.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)

                    Text(habit.description ?? "")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 10) {

                    if completed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(Color(red: 0.55, green: 0.85, blue: 0.47))
                    } else {
                        Text("+\(habit.xpReward) XP")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.74, green: 0.54, blue: 0.12))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color(red: 1.0, green: 0.96, blue: 0.84))
                            )
                    }

                    Image(systemName: completed ? "sparkles" : "arrow.up.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.secondary.opacity(0.7))
                }

            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundFill)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(
                color: Color.black.opacity(completed ? 0.08 : 0.05),
                radius: completed ? 20 : 14,
                x: 0,
                y: 10
            )
            .scaleEffect(animated ? 1.02 : 1)
            .animation(.easeOut(duration: 0.22), value: animated)
        }
        .buttonStyle(.plain)
        .disabled(completed)
    }

    private var backgroundFill: some ShapeStyle {
        LinearGradient(
            colors: completed
            ? [
                Color(red: 1.0, green: 0.97, blue: 0.82),
                Color(red: 1.0, green: 0.93, blue: 0.67)
            ]
            : [
                Color.white.opacity(0.98),
                Color(red: 0.95, green: 0.95, blue: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderColor: Color {
        completed
        ? Color(red: 0.95, green: 0.86, blue: 0.42)
        : Color.black.opacity(0.06)
    }

    private func iconName() -> String {

        let name = habit.name.lowercased()

        if name.contains("workout") || name.contains("walk") || name.contains("run") {
            return "figure.run"
        }

        if name.contains("read") {
            return "book.closed.fill"
        }

        if name.contains("meditate") || name.contains("mind") {
            return "sparkles"
        }

        if name.contains("journal") || name.contains("write") {
            return "pencil.and.outline"
        }

        if name.contains("shower") || name.contains("water") {
            return "drop.fill"
        }

        return "flame.fill"
    }
}
