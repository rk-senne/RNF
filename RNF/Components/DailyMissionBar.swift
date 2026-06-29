import SwiftUI

struct DailyMissionBar: View {

    let completed: Int
    let goal: Int
    @State private var didComplete = false
    private var progress: CGFloat {
        guard goal > 0 else { return 0 }
        return min(max(CGFloat(completed) / CGFloat(goal), 0), 1)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack {

                Text("Daily Mission")
                    .font(RNFFont.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(completed) / \(goal)")
                    .font(RNFFont.captionBoldSmall)
                    .foregroundStyle(Color(red: 0.16, green: 0.54, blue: 0.28))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.89, green: 0.97, blue: 0.89))
                    )

            }

            GeometryReader { geo in

                ZStack(alignment: .leading) {

                    Capsule()
                        .fill(RNFColors.borderSubtle)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.24, green: 0.8, blue: 0.34),
                                    Color(red: 0.13, green: 0.62, blue: 0.29)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * progress
                        )
                        .animationIfAllowed(.spring(response: 0.4), value: progress)
                        .overlay {
                            if didComplete {
                                Capsule()
                                    .fill(Color.primary.opacity(0.3))
                                    .transition(.opacity)
                            }
                        }
                }
            }
            .frame(height: 12)

            Text("\(completed) / \(goal) habits")
                .font(RNFFont.body)
                .foregroundStyle(.secondary)

        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily mission, \(completed) of \(goal) habits completed, \(Int(progress * 100)) percent")
        .onChange(of: completed) { _, newValue in
            if newValue >= goal && goal > 0 {
                withAnimation(.easeInOut(duration: 0.3)) { didComplete = true }
                Task {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    withAnimation { didComplete = false }
                }
            }
        }
    }
}
