import SwiftUI

struct LeaderboardView: View {
    let entries: [LeaderboardEntry]

    var body: some View {
        List(entries) { entry in
            HStack(spacing: 12) {
                Text("#\(entry.rank)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .frame(width: 36)
                    .foregroundStyle(entry.rank <= 3 ? .yellow : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.username ?? "User")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Text("Level \(entry.level)")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entry.xp_total) XP")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                        Text("\(entry.streak)")
                            .font(.system(size: 11, design: .rounded))
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.plain)
        .navigationTitle("Leaderboard")
    }
}
