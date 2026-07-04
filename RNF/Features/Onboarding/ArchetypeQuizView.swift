import SwiftUI

// P22-ONB-06: Animated question cards with stat distribution preview.
struct ArchetypeQuizView: View {

    let onComplete: (Archetype) -> Void

    @State private var currentIndex = 0
    @State private var answers: [StatAxis] = []
    @State private var selectedOption: ArchetypeOption?
    @State private var cardOffset: CGFloat = 0
    @State private var cardOpacity: Double = 1.0
    @State private var showResult = false
    @State private var resolvedArchetype: Archetype?

    private let questions = ArchetypeQuiz.questions

    var body: some View {
        VStack(spacing: RNFSpacing.lg) {
            Spacer(minLength: RNFSpacing.xl)

            // Progress
            HStack(spacing: RNFSpacing.xs) {
                ForEach(0..<questions.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentIndex ? RNFColors.primary : RNFColors.borderSubtle)
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, RNFSpacing.md)

            if showResult, let archetype = resolvedArchetype {
                archetypeResultCard(archetype)
                    .transition(.scale.combined(with: .opacity))
            } else {
                questionCard
                    .offset(x: cardOffset)
                    .opacity(cardOpacity)
            }

            Spacer()

            // Stat distribution preview
            if !answers.isEmpty {
                statPreview
                    .padding(.horizontal, RNFSpacing.md)
            }

            Spacer(minLength: RNFSpacing.lg)
        }
        .animationIfAllowed(.spring(response: 0.5, dampingFraction: 0.85), value: currentIndex)
        .animationIfAllowed(.spring(response: 0.6, dampingFraction: 0.8), value: showResult)
    }

    // MARK: - Question Card

    private var questionCard: some View {
        VStack(spacing: RNFSpacing.lg) {
            Text("DISCOVER YOUR PATH")
                .overlineStyle()

            Text(questions[currentIndex].prompt)
                .font(RNFFont.titleMedium)
                .foregroundStyle(RNFColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, RNFSpacing.md)

            VStack(spacing: RNFSpacing.cardSpacing) {
                ForEach(questions[currentIndex].options) { option in
                    OptionButton(
                        option: option,
                        isSelected: selectedOption == option,
                        onTap: { selectOption(option) }
                    )
                }
            }
            .padding(.horizontal, RNFSpacing.md)
        }
    }

    // MARK: - Result Card

    private func archetypeResultCard(_ archetype: Archetype) -> some View {
        VStack(spacing: RNFSpacing.lg) {
            Text(archetype.emoji)
                .font(.system(size: 64))

            Text(archetype.name)
                .font(RNFFont.title)
                .foregroundStyle(RNFColors.textPrimary)

            Text(archetype.title)
                .font(RNFFont.section)
                .foregroundStyle(RNFColors.primary)

            Text(archetype.description)
                .font(RNFFont.body)
                .foregroundStyle(RNFColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, RNFSpacing.xl)

            Button(action: { onComplete(archetype) }) {
                Text("Accept Your Path")
                    .font(RNFFont.bodySemibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RNFSpacing.md)
                    .background(RNFColors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous))
            }
            .padding(.horizontal, RNFSpacing.md)
        }
    }

    // MARK: - Stat Preview

    private var statPreview: some View {
        let distribution = ArchetypeQuiz.statDistribution(answers: answers)
        let total = max(distribution.values.reduce(0, +), 1)

        return HStack(spacing: RNFSpacing.sm) {
            ForEach(StatAxis.allCases, id: \.self) { axis in
                let value = distribution[axis] ?? 0
                let fraction = CGFloat(value) / CGFloat(total)

                VStack(spacing: RNFSpacing.xs) {
                    Text(axis.emoji)
                        .font(.caption)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(statColor(for: axis))
                            .frame(height: geo.size.height * fraction)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    .frame(height: 40)
                    Text(axis.displayName)
                        .font(RNFFont.captionSmall)
                        .foregroundStyle(RNFColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(RNFSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.sm, style: .continuous)
                .fill(RNFColors.surface)
        )
    }

    // MARK: - Actions

    private func selectOption(_ option: ArchetypeOption) {
        selectedOption = option
        RNFHaptics.selection()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            answers.append(option.axis)

            if currentIndex < questions.count - 1 {
                advanceToNext()
            } else {
                resolveArchetype()
            }
        }
    }

    private func advanceToNext() {
        withAnimation(.easeIn(duration: 0.2)) {
            cardOffset = -300
            cardOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            currentIndex += 1
            selectedOption = nil
            cardOffset = 300

            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                cardOffset = 0
                cardOpacity = 1
            }
        }
    }

    private func resolveArchetype() {
        let archetype = ArchetypeQuiz.resolve(answers: answers)
        resolvedArchetype = archetype
        showResult = true
        RNFHaptics.success()
    }

    private func statColor(for axis: StatAxis) -> Color {
        switch axis {
        case .body: return RNFColors.statStrength
        case .mind: return RNFColors.statWisdom
        case .spirit: return RNFColors.statSpirit
        }
    }
}

// MARK: - Option Button

private struct OptionButton: View {

    let option: ArchetypeOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: RNFSpacing.md) {
                Text(option.axis.emoji)
                    .font(.title3)

                Text(option.text)
                    .font(RNFFont.bodySemibold)
                    .foregroundStyle(isSelected ? .white : RNFColors.textPrimary)

                Spacer()
            }
            .padding(RNFSpacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous)
                    .fill(isSelected ? RNFColors.primary : RNFColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RNFRadius.md, style: .continuous)
                    .stroke(isSelected ? RNFColors.primary : RNFColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.text), \(option.axis.displayName)")
    }
}
