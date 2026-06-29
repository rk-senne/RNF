import SwiftUI

// P20-EXP-09b: Memory card displaying a milestone snapshot with optional comparison
struct MemoryCardView: View {
    let snapshot: ProgressSnapshot
    var currentStats: [Double]?

    private let labels = ["Strength", "Discipline", "Focus", "Energy", "Wisdom", "Mind", "Spirit"]

    var body: some View {
        VStack(alignment: .leading, spacing: RNFSpacing.cardSpacing) {
            Text("\(snapshot.milestone.uppercased()) MEMORY")
                .overlineStyle()

            Text(formattedDate)
                .font(RNFFont.caption)
                .foregroundStyle(RNFColors.textSecondary)

            HStack(spacing: RNFSpacing.md) {
                statPill("LVL \(snapshot.level)")
                statPill("🔥 \(snapshot.streak)")
                statPill("\(snapshot.xpTotal) XP")
            }

            if let current = currentStats {
                VStack(alignment: .leading, spacing: RNFSpacing.xs) {
                    ForEach(0..<min(labels.count, snapshot.stats.count, current.count), id: \.self) { i in
                        let past = Int(snapshot.stats[i] * 20)
                        let now = Int(current[i] * 20)
                        if now != past {
                            Text("Then: \(labels[i]) \(past) → Now: \(labels[i]) \(now)")
                                .font(RNFFont.caption)
                                .foregroundStyle(RNFColors.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(RNFSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RNFColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RNFRadius.card))
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: snapshot.dateString) else { return snapshot.dateString }
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func statPill(_ text: String) -> some View {
        Text(text)
            .font(RNFFont.pill)
            .foregroundStyle(RNFColors.textPrimary)
            .padding(.horizontal, RNFSpacing.sm)
            .padding(.vertical, RNFSpacing.xs)
            .background(RNFColors.surfaceElevated)
            .clipShape(Capsule())
    }
}
