import SwiftUI

struct CircularProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 12

    var body: some View {
        ZStack {
            Circle()
                .stroke(RNFColors.borderSubtle, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animationIfAllowed(.spring(response: 0.4), value: progress)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily progress")
        .accessibilityValue("\(Int(min(max(progress, 0), 1) * 100)) percent complete")
    }

    private var ringColor: Color {
        let clamped = min(max(progress, 0), 1)
        if clamped < 0.5 {
            return RNFColors.quest
        } else if clamped < 0.8 {
            return Color(
                red: 0.3 + (clamped - 0.5) * 0.6,
                green: 0.43 + (clamped - 0.5) * 0.7,
                blue: 0.86 - (clamped - 0.5) * 1.4
            )
        } else {
            return RNFColors.success
        }
    }
}
