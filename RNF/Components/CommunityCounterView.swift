import SwiftUI

/// P24-RET-09: Community counter showing "X habits completed today" with a count-up animation.
/// Accepts a binding so the parent can update the count in real-time.
struct CommunityCounterView: View {

    @Binding var count: Int

    @State private var displayedCount: Int = 0
    @State private var animationTimer: Timer?

    var body: some View {
        HStack(spacing: RNFSpacing.sm) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(RNFColors.primary)

            Text("\(displayedCount)")
                .font(RNFFont.metricSmall)
                .foregroundStyle(RNFColors.textPrimary)
                .contentTransition(.numericText())

            Text("habits completed today")
                .font(RNFFont.caption)
                .foregroundStyle(RNFColors.textSecondary)
        }
        .padding(.horizontal, RNFSpacing.md)
        .padding(.vertical, RNFSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.sm, style: .continuous)
                .fill(RNFColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RNFRadius.sm, style: .continuous)
                .strokeBorder(RNFColors.borderSubtle, lineWidth: 1)
        )
        .onAppear {
            animateCountUp(to: count)
        }
        .onChange(of: count) { _, newValue in
            animateCountUp(to: newValue)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) habits completed today by the community")
    }

    // MARK: - Count-Up Animation

    private func animateCountUp(to target: Int) {
        animationTimer?.invalidate()

        guard target != displayedCount else { return }

        let steps = min(abs(target - displayedCount), 30)
        guard steps > 0 else {
            displayedCount = target
            return
        }

        let increment = target > displayedCount ? 1 : -1
        let totalDuration: Double = 0.8
        let interval = totalDuration / Double(steps)

        var currentStep = 0

        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            currentStep += 1

            withAnimation(.easeOut(duration: interval)) {
                if currentStep >= steps {
                    displayedCount = target
                    timer.invalidate()
                } else {
                    displayedCount += increment
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var communityCount = 1247

        var body: some View {
            VStack(spacing: 24) {
                CommunityCounterView(count: $communityCount)

                Button("Add 50") {
                    communityCount += 50
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
