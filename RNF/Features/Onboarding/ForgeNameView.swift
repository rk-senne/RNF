import SwiftUI

// P22-ONB-07: Name input with forge ignition animation.
struct ForgeNameView: View {

    let onComplete: (String) -> Void

    @State private var playerName = ""
    @State private var forgeIgnited = false
    @State private var glowIntensity: Double = 0
    @State private var shakeOffset: CGFloat = 0
    @FocusState private var isNameFocused: Bool

    private var isValidName: Bool {
        let trimmed = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= 20
    }

    var body: some View {
        VStack(spacing: RNFSpacing.lg) {
            Spacer(minLength: RNFSpacing.xxl)

            // Forge icon with glow
            ZStack {
                Circle()
                    .fill(RNFColors.primary.opacity(glowIntensity * 0.3))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Image(systemName: "flame.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        forgeIgnited
                            ? LinearGradient(colors: [RNFColors.primary, RNFColors.primaryLight], startPoint: .bottom, endPoint: .top)
                            : LinearGradient(colors: [RNFColors.textTertiary, RNFColors.textSecondary], startPoint: .bottom, endPoint: .top)
                    )
                    .scaleEffect(forgeIgnited ? 1.1 : 1.0)
            }

            VStack(spacing: RNFSpacing.sm) {
                Text("FORGE YOUR IDENTITY")
                    .overlineStyle()

                Text("Choose Your Name")
                    .font(RNFFont.title)
                    .foregroundStyle(RNFColors.textPrimary)

                Text("This is how you'll be known in the forge")
                    .font(RNFFont.body)
                    .foregroundStyle(RNFColors.textSecondary)
            }
            .multilineTextAlignment(.center)

            Spacer(minLength: RNFSpacing.md)

            // Name input
            VStack(spacing: RNFSpacing.sm) {
                TextField("Enter your name", text: $playerName)
                    .font(RNFFont.section)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($isNameFocused)
                    .padding(RNFSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous)
                            .fill(RNFColors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous)
                            .stroke(forgeIgnited ? RNFColors.primary : RNFColors.borderSubtle, lineWidth: forgeIgnited ? 2 : 1)
                    )
                    .offset(x: shakeOffset)
                    .padding(.horizontal, RNFSpacing.xl)
                    .onChange(of: playerName) { _ in
                        updateForgeState()
                    }

                Text("\(playerName.count)/20")
                    .font(RNFFont.captionSmall)
                    .foregroundStyle(playerName.count > 20 ? RNFColors.destructive : RNFColors.textTertiary)
            }

            Spacer()

            // Ignite button
            Button(action: igniteForge) {
                HStack(spacing: RNFSpacing.sm) {
                    Image(systemName: "flame.fill")
                    Text("Ignite The Forge")
                }
                .font(RNFFont.bodySemibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, RNFSpacing.md)
                .background(isValidName ? RNFColors.primary : RNFColors.primary.opacity(0.4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous))
            }
            .disabled(!isValidName)
            .padding(.horizontal, RNFSpacing.md)

            Spacer(minLength: RNFSpacing.lg)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
        }
        .animationIfAllowed(.spring(response: 0.5, dampingFraction: 0.7), value: forgeIgnited)
    }

    // MARK: - Actions

    private func updateForgeState() {
        let shouldIgnite = isValidName
        if shouldIgnite != forgeIgnited {
            forgeIgnited = shouldIgnite
            withAnimation(.easeInOut(duration: 0.6)) {
                glowIntensity = shouldIgnite ? 1.0 : 0
            }
            if shouldIgnite {
                RNFHaptics.selection()
            }
        }
    }

    private func igniteForge() {
        guard isValidName else {
            withAnimation(.default) {
                shakeOffset = -8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.default) { shakeOffset = 8 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.default) { shakeOffset = 0 }
            }
            return
        }

        RNFHaptics.success()
        let name = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        onComplete(name)
    }
}
