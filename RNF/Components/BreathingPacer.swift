import SwiftUI

// P20-EXP-08c: Breathing Pacer — animated inhale/exhale circle
struct BreathingPacer: View {
    @State private var expanded = false
    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    var body: some View {
        Circle()
            .fill(RNFColors.primary.opacity(0.2))
            .frame(width: expanded ? 60 : 30, height: expanded ? 60 : 30)
            .overlay(
                Text(expanded ? "Out" : "In")
                    .font(RNFFont.caption)
                    .foregroundStyle(.secondary)
            )
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    expanded = true
                }
            }
            .accessibilityLabel("Breathing pacer. Expand for inhale, contract for exhale.")
    }
}
