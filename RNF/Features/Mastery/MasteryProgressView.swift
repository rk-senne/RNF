import SwiftUI

struct MasteryProgressView: View {
    let path: MasteryPath

    private var tierProgress: Double {
        let thresholds = MasteryPath.tierThresholds
        let currentTierStart = path.tier <= thresholds.count ? thresholds[path.tier - 1] : 0
        let nextTierStart = path.tier < thresholds.count ? thresholds[path.tier] : currentTierStart + 5000
        let range = nextTierStart - currentTierStart
        guard range > 0 else { return 1 }
        return Double(path.xpInPath - currentTierStart) / Double(range)
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(path.pathType.rawValue.capitalized)
                    .font(RNFFont.heroSubtitle)
                Text(path.title)
                    .font(RNFFont.body)
                    .foregroundStyle(.purple)
            }

            VStack(spacing: 8) {
                Text("Tier \(path.tier)")
                    .font(RNFFont.captionBold)
                ProgressView(value: max(0, min(tierProgress, 1)))
                    .tint(.purple)
                Text("\(path.xpInPath) XP")
                    .font(RNFFont.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemBackground)))
        }
        .padding()
        .navigationTitle("Mastery Progress")
    }
}
