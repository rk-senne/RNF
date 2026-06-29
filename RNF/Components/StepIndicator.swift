import SwiftUI

struct StepIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i == current ? RNFColors.primary : RNFColors.borderSubtle)
                    .frame(width: i == current ? 10 : 6, height: i == current ? 10 : 6)
                    .animationIfAllowed(.spring(response: 0.3), value: current)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }
}
