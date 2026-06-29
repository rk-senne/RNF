import SwiftUI

struct RNFTabBar: View {

    @Binding var selection: Int
    let incompleteCount: Int

    private let tabs: [(icon: String, label: String)] = [
        ("checkmark.circle", "Habits"),
        ("figure.strengthtraining.traditional", "Workouts"),
        ("book.closed.fill", "Read"),
        ("flame.fill", "Ascension")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button {
                    selection = index
                    RNFHaptics.selection()
                } label: {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 18, weight: selection == index ? .bold : .medium))

                            if index == 0 && incompleteCount > 0 {
                                Circle()
                                    .fill(RNFColors.destructive)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 6, y: -4)
                            }
                        }

                        Text(tab.label)
                            .font(.system(size: 10, weight: selection == index ? .bold : .medium, design: .rounded))
                    }
                    .foregroundStyle(selection == index ? RNFColors.primary : RNFColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if selection == index {
                            Capsule()
                                .fill(RNFColors.primary.opacity(0.1))
                                .padding(.horizontal, 12)
                        }
                    }
                    .animationIfAllowed(.spring(response: 0.25), value: selection)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(tab.label)\(index == 0 && incompleteCount > 0 ? ", \(incompleteCount) remaining" : "")")
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(.ultraThinMaterial)
    }
}
