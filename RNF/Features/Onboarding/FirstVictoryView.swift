import SwiftUI

// P22-ONB-09: Shows earned XP, level, and Spark Initiate title.
struct FirstVictoryView: View {

    let xpEarned: Int
    let level: Int
    let playerName: String
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var xpCounterValue: Int = 0
    @State private var showTitle = false
    @State private var showButton = false
    @State private var glowPulse = false

    private let sparkTitle = "Spark Initiate"

    var body: some View {
        VStack(spacing: RNFSpacing.xl) {
            Spacer(minLength: RNFSpacing.xxl)

            // Victory flame
            ZStack {
                Circle()
                    .fill(RNFColors.primary.opacity(glowPulse ? 0.25 : 0.1))
                    .frame(width: 140, height: 140)
                    .blur(radius: 24)

                Image(systemName: "flame.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [RNFColors.primary, RNFColors.primaryLight],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .opacity(showContent ? 1 : 0)
            }

            // XP counter
            VStack(spacing: RNFSpacing.sm) {
                Text("FIRST VICTORY")
                    .overlineStyle()
                    .opacity(showContent ? 1 : 0)

                Text("+\(xpCounterValue) XP")
                    .font(RNFFont.displayLarge)
                    .foregroundStyle(RNFColors.primary)
                    .contentTransition(.numericText())

                Text("Level \(level)")
                    .font(RNFFont.heroSubtitle)
                    .foregroundStyle(RNFColors.textPrimary)
                    .opacity(showContent ? 1 : 0)
            }

            // Title reveal
            if showTitle {
                VStack(spacing: RNFSpacing.sm) {
                    Text("Title Earned")
                        .font(RNFFont.caption)
                        .foregroundStyle(RNFColors.textTertiary)

                    HStack(spacing: RNFSpacing.sm) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(RNFColors.primary)
                        Text(sparkTitle)
                            .font(RNFFont.section)
                            .foregroundStyle(RNFColors.textPrimary)
                        Image(systemName: "sparkles")
                            .foregroundStyle(RNFColors.primary)
                    }

                    Text(playerName)
                        .font(RNFFont.body)
                        .foregroundStyle(RNFColors.textSecondary)
                }
                .padding(RNFSpacing.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: RNFRadius.lg, style: .continuous)
                        .fill(RNFColors.surface)
                )
                .rnfShadow(.card)
                .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            // Continue button
            if showButton {
                Button(action: onContinue) {
                    Text("Begin Your Journey")
                        .font(RNFFont.bodySemibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, RNFSpacing.md)
                        .background(RNFColors.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous))
                }
                .padding(.horizontal, RNFSpacing.md)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer(minLength: RNFSpacing.lg)
        }
        .onAppear(perform: playSequence)
    }

    // MARK: - Animation Sequence

    private func playSequence() {
        // Step 1: Show content
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showContent = true
        }

        // Step 2: Count up XP
        animateXPCounter()

        // Step 3: Reveal title
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showTitle = true
            }
            RNFHaptics.success()
        }

        // Step 4: Show button
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.4)) {
                showButton = true
            }
        }

        // Glow pulse loop
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowPulse = true
        }
    }

    private func animateXPCounter() {
        let steps = 20
        let interval = 0.8 / Double(steps)
        let increment = max(xpEarned / steps, 1)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(step) * interval) {
                xpCounterValue = min(increment * step, xpEarned)
            }
        }
    }
}
