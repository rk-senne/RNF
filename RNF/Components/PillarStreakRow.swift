import SwiftUI

// P20-EXP-16c: Pillar streak display row
struct PillarStreakRow: View {
    let streaks: PillarStreaks

    var body: some View {
        HStack(spacing: 12) {
            pill("🔥", streaks.habits)
            pill("💪", streaks.workouts)
            pill("📖", streaks.reading)
            pill("🧠", streaks.focus)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Streaks: habits \(streaks.habits), workouts \(streaks.workouts), reading \(streaks.reading), focus \(streaks.focus)")
    }

    private func pill(_ icon: String, _ count: Int) -> some View {
        HStack(spacing: 3) {
            Text(icon).font(.system(size: 12))
            Text("\(count)").font(RNFFont.pill).foregroundStyle(RNFColors.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(RNFColors.surfaceElevated, in: Capsule())
    }
}
