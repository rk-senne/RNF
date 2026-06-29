import SwiftUI

// P20-EXP-14d: Discovery log showing earned and locked discoveries
struct DiscoveryLogView: View {

    private let history = DiscoveryService.loadHistory()
    private let allDiscoveries = PassiveDiscoverySystem.allDiscoveries

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                HStack {
                    Text("DISCOVERIES")
                        .overlineStyle()
                    Spacer()
                    Text("\(history.count)/\(allDiscoveries.count)")
                        .font(RNFFont.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(allDiscoveries) { discovery in
                    if let record = history.first(where: { $0.discoveryID == discovery.id }) {
                        earnedRow(discovery: discovery, record: record)
                    } else {
                        lockedRow(discovery: discovery)
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Discoveries")
        .navigationBarTitleDisplayMode(.large)
    }

    private func earnedRow(discovery: Discovery, record: DiscoveryRecord) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(discovery.rarity.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(discovery.name)
                        .font(RNFFont.bodyBold)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("+\(discovery.xp) XP")
                        .font(RNFFont.caption)
                        .foregroundStyle(Color(hex: "#D4AF37"))
                }

                Text(discovery.message)
                    .font(RNFFont.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(record.earnedDate)
                        .font(RNFFont.pill)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text(discovery.rarity.rawValue.uppercased())
                        .font(RNFFont.pillSmall)
                        .foregroundStyle(discovery.rarity.color)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                .fill(RNFColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                .strokeBorder(RNFColors.borderSubtle, lineWidth: 1)
        )
    }

    private func lockedRow(discovery: Discovery) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(discovery.rarity.color.opacity(0.4))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text("???")
                    .font(RNFFont.bodyBold)
                    .foregroundStyle(.secondary)

                Text(discovery.rarity.hint)
                    .font(RNFFont.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text(discovery.rarity.rawValue.uppercased())
                .font(RNFFont.pillSmall)
                .foregroundStyle(discovery.rarity.color.opacity(0.5))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                .fill(RNFColors.surface.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                .strokeBorder(RNFColors.borderSubtle.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Rarity helpers

extension Discovery.Rarity {
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .legendary: return Color(hex: "#D4AF37")
        }
    }

    var hint: String {
        switch self {
        case .common: return "Found through daily habits"
        case .uncommon: return "Requires consistency"
        case .rare: return "A rare achievement awaits"
        case .legendary: return "Only the most dedicated"
        }
    }
}
