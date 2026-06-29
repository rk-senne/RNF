import SwiftUI

// P20-EXP-09b: Overlay comparison of past vs current radar stats
struct RadarComparisonView: View {
    let past: [Double]
    let current: [Double]

    var body: some View {
        ZStack {
            RadarGrid()

            // Past: faded dashed
            RadarShape(values: past)
                .fill(RNFColors.primary.opacity(0.2))
            RadarShape(values: past)
                .stroke(RNFColors.primary.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))

            // Current: solid fill + stroke
            RadarShape(values: current)
                .fill(
                    RadialGradient(
                        colors: [RNFColors.primary.opacity(0.15), RNFColors.primary.opacity(0.4)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 90
                    )
                )
            RadarShape(values: current)
                .stroke(RNFColors.primary, lineWidth: 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(height: 180)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Radar comparison: past versus current stats")
    }
}
