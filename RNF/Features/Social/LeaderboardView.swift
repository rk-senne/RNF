import SwiftUI

struct LeaderboardView: View {
    let entries: [LeaderboardEntry]

    var body: some View {
        List(entries) { entry in
            HStack(spacing: 12) {
                Text("#\(entry.rank)")
                    .font(RNFFont.bodyBold)
                    .frame(width: 36)
                    .foregroundStyle(entry.rank <= 3 ? .yellow : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.username ?? "User")
                        .font(RNFFont.bodyBold)
                    Text("Level \(entry.level)")
                        .font(RNFFont.captionSmall)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entry.xp_total) XP")
                        .font(RNFFont.caption)
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                        Text("\(entry.streak)")
                            .font(RNFFont.pill)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.plain)
        .navigationTitle("Leaderboard")
    }
}
