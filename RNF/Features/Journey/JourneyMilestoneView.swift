import SwiftUI

// P20-EXP-07b: Individual milestone node for the journey map
struct JourneyMilestoneView: View {
    let milestone: JourneyMilestone
    let isPassed: Bool
    let isCurrent: Bool

    @State private var pulseScale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: RNFSpacing.xs) {
            ZStack {
                Circle()
                    .fill(isPassed ? RNFColors.success.opacity(0.15) : RNFColors.surface)
                    .frame(width: 48, height: 48)

                if isCurrent {
                    Circle()
                        .stroke(RNFColors.primary, lineWidth: 2)
                        .frame(width: 48, height: 48)
                        .scaleEffect(pulseScale)
                        .opacity(Double(2 - pulseScale))
                        .onAppear {
                            guard !reduceMotion else { return }
                            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                                pulseScale = 1.4
                            }
                        }
                }

                Text(milestone.icon)
                    .font(.system(size: 24))
            }

            Text("Day \(milestone.day)")
                .font(RNFFont.caption)
                .foregroundStyle(RNFColors.textSecondary)

            Text(milestone.name)
                .font(RNFFont.pill)
                .foregroundStyle(RNFColors.textPrimary)
        }
        .opacity(isPassed || isCurrent ? 1.0 : 0.4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(milestone.name), day \(milestone.day), \(isPassed ? "completed" : isCurrent ? "current" : "upcoming")")
    }
}
