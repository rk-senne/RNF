import SwiftUI

struct XPBar: View {

    let xp: Int
    let levelXP: Int
    let level: Int
    private var progress: CGFloat {
        guard levelXP > 0 else { return 0 }
        return min(max(CGFloat(xp) / CGFloat(levelXP), 0), 1)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack {

                Text(rankTitle())
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Level \(level)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(levelColor())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(levelColor().opacity(0.14))
                    )

            }

            GeometryReader { geo in

                ZStack(alignment: .leading) {

                    Capsule()
                        .fill(Color.black.opacity(0.06))

                    Capsule()
                        .fill(levelColor())
                        .frame(
                            width: geo.size.width * progress
                        )
                }

            }
            .frame(height: 12)

            Text("\(xp) / \(levelXP) XP")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

        }
    }

    func levelColor() -> Color {

        switch level {

        case 1...4: return Color(red: 0.84, green: 0.66, blue: 0.14)
        case 5...9: return Color(red: 0.79, green: 0.24, blue: 0.86)
        case 10...14: return Color(red: 0.85, green: 0.22, blue: 0.22)
        case 15...19: return Color(red: 0.13, green: 0.45, blue: 0.9)
        default: return Color.primary

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
