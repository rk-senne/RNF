import SwiftUI

struct DailyMissionBar: View {

    let completed: Int
    let goal: Int
    private var progress: CGFloat {
        guard goal > 0 else { return 0 }
        return min(max(CGFloat(completed) / CGFloat(goal), 0), 1)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack {

                Text("Daily Mission")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(completed) / \(goal)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
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
                        .fill(Color.black.opacity(0.06))

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
                }
            }
            .frame(height: 12)

            Text("\(completed) / \(goal) habits")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

        }
    }
}
