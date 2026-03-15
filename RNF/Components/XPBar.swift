import SwiftUI

struct XPBar: View {

    let xp: Int
    let levelXP: Int
    let level: Int

    var body: some View {

        VStack(alignment: .leading, spacing: 6) {

            Text(rankTitle())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gray)

            GeometryReader { geo in

                ZStack(alignment: .leading) {

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(levelColor())
                        .frame(
                            width: geo.size.width *
                            CGFloat(xp) /
                            CGFloat(levelXP)
                        )
                }

            }
            .frame(height: 10)

            Text("\(xp) / \(levelXP) XP")
                .font(.caption2)
                .foregroundColor(.gray)

        }
        .padding(.horizontal)
    }

    func levelColor() -> Color {

        switch level {

        case 1...4: return .yellow
        case 5...9: return .purple
        case 10...14: return .red
        case 15...19: return .blue
        default: return .white

        }
    }

    func rankTitle() -> String {

        switch level {

        case 1...4: return "DISCIPLE"
        case 5...9: return "AWAKENED"
        case 10...14: return "ASCENDANT"
        case 15...19: return "WARLORD"
        default: return "APEX"

        }
    }
}
