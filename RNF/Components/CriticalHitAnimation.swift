import SwiftUI

/// P24-RET-03: Gold flash effect with screen shake and haptic feedback.
/// Use as an overlay on the parent view; toggle `isActive` to trigger.
struct CriticalHitAnimation: View {

    @Binding var isActive: Bool

    @State private var flashOpacity: Double = 0
    @State private var shakeOffset: CGFloat = 0
    @State private var showBurst: Bool = false

    var body: some View {
        ZStack {
            // Gold flash overlay
            Color(red: 1.0, green: 0.84, blue: 0.0)
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Burst particle effect
            if showBurst {
                burstEffect
                    .transition(.opacity)
            }
        }
        .offset(x: shakeOffset)
        .onChange(of: isActive) { _, active in
            if active {
                triggerCriticalHit()
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Burst Effect

    private var burstEffect: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8))
                    .frame(width: 8, height: 8)
                    .offset(burstOffset(for: index))
                    .opacity(showBurst ? 0 : 1)
            }
        }
    }

    private func burstOffset(for index: Int) -> CGSize {
        let angle = Double(index) * (.pi / 4)
        let distance: Double = showBurst ? 80 : 0
        return CGSize(
            width: Foundation.cos(angle) * distance,
            height: Foundation.sin(angle) * distance
        )
    }

    // MARK: - Trigger

    private func triggerCriticalHit() {
        // Haptic feedback — heavy impact for "critical hit" feel
        RNFHaptics.impact(.heavy)

        // Gold flash
        withAnimation(.easeIn(duration: 0.08)) {
            flashOpacity = 0.4
        }

        // Shake sequence
        shakeSequence()

        // Burst particles
        withAnimation(.easeOut(duration: 0.4)) {
            showBurst = true
        }

        // Fade out flash
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.3)) {
                flashOpacity = 0
            }
        }

        // Reset state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showBurst = false
            isActive = false
        }
    }

    private func shakeSequence() {
        let offsets: [CGFloat] = [10, -8, 6, -4, 2, 0]
        for (index, offset) in offsets.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.04) {
                withAnimation(.linear(duration: 0.04)) {
                    shakeOffset = offset
                }
            }
        }
    }
}

// MARK: - View Modifier

extension View {
    /// Applies a critical hit overlay with gold flash, shake, and haptic.
    func criticalHitOverlay(isActive: Binding<Bool>) -> some View {
        self.overlay {
            CriticalHitAnimation(isActive: isActive)
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var trigger = false

        var body: some View {
            VStack(spacing: 24) {
                Text("Critical Hit!")
                    .font(RNFFont.display)

                Button("Trigger") {
                    trigger = true
                }
                .buttonStyle(.borderedProminent)
            }
            .criticalHitOverlay(isActive: $trigger)
        }
    }

    return PreviewWrapper()
}
