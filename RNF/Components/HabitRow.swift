import SwiftUI

struct HabitRow: View {

    let habit: Habit
    let completed: Bool
    let animated: Bool
    let action: () -> Void

    // P20-EXP-02b: Multi-phase completion animation
    @State private var showXPFloat = false
    @State private var completionPhase: CompletionPhase = .idle

    private enum CompletionPhase {
        case idle, pressed, expanded, settled
    }

    private var phaseScale: CGFloat {
        switch completionPhase {
        case .idle: return 1.0
        case .pressed: return 0.96
        case .expanded: return 1.03
        case .settled: return 1.0
        }
    }

    private var accentColor: Color {
        completed
        ? Color(red: 0.81, green: 0.67, blue: 0.16)
        : Color(red: 0.17, green: 0.17, blue: 0.2)
    }

    var body: some View {

        Button {
            triggerCompletion()
        } label: {

            HStack(spacing: 14) {

                ZStack {

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(accentColor.opacity(completed ? 0.16 : 0.08))
                        .frame(width: 56, height: 56)

                    Image(systemName: iconName())
                        .font(RNFFont.iconLabel)
                        .foregroundStyle(accentColor)

                }

                VStack(alignment: .leading, spacing: 6) {

                    Text(habit.name)
                        .font(RNFFont.section)
                        .foregroundStyle(Color.primary)

                    Text(habit.description ?? "")
                        .font(RNFFont.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 10) {

                    if completed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(RNFFont.titleMedium)
                            .foregroundStyle(Color(red: 0.55, green: 0.85, blue: 0.47))
                    } else {
                        Text("+\(habit.xpReward) XP")
                            .font(RNFFont.captionBoldSmall)
                            .foregroundStyle(Color(red: 0.74, green: 0.54, blue: 0.12))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color(red: 1.0, green: 0.96, blue: 0.84))
                            )
                    }

                    Image(systemName: completed ? "sparkles" : "arrow.up.right")
                        .font(RNFFont.captionBold)
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
            .scaleEffect(animated ? 1.02 : phaseScale)
            .animationIfAllowed(.easeOut(duration: 0.22), value: animated)
            .animationIfAllowed(.spring(response: 0.35, dampingFraction: 0.6), value: completionPhase)
            .overlay(alignment: .topTrailing) {
                FloatingXPText(xp: habit.xpReward, visible: showXPFloat)
                    .padding(.trailing, 16)
                    .padding(.top, -8)
            }
        }
        .buttonStyle(.plain)
        .disabled(completed)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(habit.name), \(completed ? "completed" : "not completed, plus \(habit.xpReward) XP")")
        .accessibilityAddTraits(completed ? [] : .isButton)
    }

    private func triggerCompletion() {
        completionPhase = .pressed
        showXPFloat = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completionPhase = .expanded
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completionPhase = .settled
            action()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            showXPFloat = false
        }
    }

    private var backgroundFill: some ShapeStyle {
        LinearGradient(
            colors: completed
            ? [
                Color(red: 1.0, green: 0.97, blue: 0.82),
                Color(red: 1.0, green: 0.93, blue: 0.67)
            ]
            : [
                RNFColors.surface,
                RNFColors.surfaceElevated
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderColor: Color {
        completed
        ? Color(red: 0.95, green: 0.86, blue: 0.42)
        : RNFColors.borderSubtle
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
