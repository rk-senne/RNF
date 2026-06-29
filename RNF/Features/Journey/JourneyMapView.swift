import SwiftUI

// P20-EXP-07b: Horizontally scrollable journey map showing milestone progress
struct JourneyMapView: View {
    let currentDay: Int
    var milestones: [JourneyMilestone] = JourneyMilestone.defaults
    var onMilestoneTapped: (String) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dotOpacity: Double = 1.0

    var body: some View {
        VStack(spacing: RNFSpacing.md) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(Array(milestones.enumerated()), id: \.element.id) { index, milestone in
                            let isPassed = currentDay >= milestone.day
                            let isCurrent = currentMilestoneIndex == index

                            if index > 0 {
                                connector(passed: currentDay >= milestone.day)
                            }

                            Button {
                                if isPassed { onMilestoneTapped(milestone.id) }
                            } label: {
                                JourneyMilestoneView(
                                    milestone: milestone,
                                    isPassed: isPassed,
                                    isCurrent: isCurrent
                                )
                            }
                            .disabled(!isPassed)
                            .minimumTapTarget()
                            .id(milestone.id)

                            // Pulsing current-position dot between milestones
                            if isCurrent, index < milestones.count - 1 {
                                currentPositionDot
                            }
                        }
                    }
                    .padding(.horizontal, RNFSpacing.lg)
                    .padding(.vertical, RNFSpacing.md)
                }
                .onAppear {
                    if let id = currentScrollTarget {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }

            // P20-EXP-07d: Begin New Arc placeholder
            if currentDay >= 90 {
                Button("Begin New Arc") { }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Subviews

    private func connector(passed: Bool) -> some View {
        Rectangle()
            .fill(passed ? RNFColors.success : RNFColors.border)
            .frame(width: 32, height: 2)
    }

    private var currentPositionDot: some View {
        Circle()
            .fill(RNFColors.primary)
            .frame(width: 10, height: 10)
            .opacity(dotOpacity)
            .padding(.horizontal, RNFSpacing.sm)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    dotOpacity = 0.3
                }
            }
    }

    // MARK: - Helpers

    private var currentMilestoneIndex: Int {
        // The last milestone whose day <= currentDay
        let passedIndices = milestones.indices.filter { currentDay >= milestones[$0].day }
        return passedIndices.last ?? 0
    }

    private var currentScrollTarget: String? {
        milestones.indices.contains(currentMilestoneIndex) ? milestones[currentMilestoneIndex].id : nil
    }
}
