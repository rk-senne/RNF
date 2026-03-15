import SwiftUI

struct DailyMissionBar: View {

    let completed: Int
    let goal: Int

    var body: some View {

        VStack(alignment: .leading, spacing: 6) {

            Text("Daily Mission")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gray)

            GeometryReader { geo in

                ZStack(alignment: .leading) {

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.green)
                        .frame(
                            width: geo.size.width *
                            CGFloat(completed) /
                            CGFloat(goal)
                        )
                }
            }
            .frame(height: 10)

            Text("\(completed) / \(goal) habits")
                .font(.caption2)
                .foregroundColor(.gray)

        }
        .padding(.horizontal)
    }
}
