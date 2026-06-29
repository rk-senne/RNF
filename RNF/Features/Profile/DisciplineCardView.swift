import SwiftUI

// P20-EXP-04a: Discipline Card View — shareable visual identity card
struct DisciplineCardView: View {

    let level: Int
    let streak: Int
    let tierName: String
    let tierIcon: String
    let stats: [Double]
    let tagline: String

    var body: some View {
        VStack(spacing: RNFSpacing.cardSpacing) {
            Spacer()

            // Tier icon
            Text(tierIcon)
                .font(.system(size: 48))

            // Tier name
            Text(tierName.uppercased())
                .font(RNFFont.display)
                .foregroundStyle(.white)

            // Level & streak subtitle
            Text("Level \(level) • \(streak) Day Streak")
                .font(RNFFont.section)
                .foregroundStyle(.white.opacity(0.85))

            // Compact radar chart
            RadarShape(values: stats)
                .fill(.white.opacity(0.2))
                .overlay(
                    RadarShape(values: stats)
                        .stroke(.white, lineWidth: 1.5)
                )
                .frame(width: 120, height: 120)

            // Tagline
            Text(tagline)
                .font(.system(size: 14, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, RNFSpacing.md)

            Spacer()

            // Wordmark
            Text("─── RNF ───")
                .font(RNFFont.overline)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, RNFSpacing.lg)
        }
        .frame(width: 360, height: 520)
        .background(tierGradient)
        .clipShape(RoundedRectangle(cornerRadius: RNFRadius.card))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(tierName) discipline card. Level \(level), \(streak) day streak.")
    }

    private var tierGradient: LinearGradient {
        let colors: [Color] = switch tierName.lowercased() {
        case "disciple":
            [Color(hex: "#F59E0B"), Color(hex: "#D97706")]
        case "awakened":
            [Color(hex: "#8B5CF6"), Color(hex: "#6D28D9")]
        case "ascendant":
            [Color(hex: "#DC2626"), Color(hex: "#991B1B")]
        case "warlord":
            [Color(hex: "#1E40AF"), Color(hex: "#1E3A5F")]
        case "apex":
            [Color(hex: "#9CA3AF"), Color(hex: "#6B7280")]
        default:
            [Color(hex: "#7C3AED"), Color(hex: "#4C1D95")]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

#Preview {
    DisciplineCardView(
        level: 12,
        streak: 45,
        tierName: "Awakened",
        tierIcon: "🔮",
        stats: [0.8, 0.6, 0.7, 0.5, 0.4, 0.6, 0.3],
        tagline: "\"Discipline is the bridge between goals and accomplishment.\""
    )
}
