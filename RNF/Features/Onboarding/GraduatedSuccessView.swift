import SwiftUI

// MARK: - P22-EMO-06: Graduated Success View

/// Tier-appropriate narrative based on completion ratio (1/4, 2/4, 3/4, 4/4).
/// Celebrates partial completion without shaming incomplete days.
struct GraduatedSuccessView: View {

    /// Number of habits completed today.
    var completed: Int = 0
    /// Total habits assigned today.
    var total: Int = 4
    var onContinue: () -> Void = {}

    var body: some View {

        VStack(alignment: .leading, spacing: 24) {

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 12) {
                Text(tier.overline)
                    .overlineStyle()

                Text(tier.headline)
                    .font(RNFFont.display)
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(tier.narrative)
                    .font(RNFFont.sectionMedium)
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Progress visualization
            progressCard

            // Encouragement detail
            if let detail = tier.detail {
                Text(detail)
                    .font(RNFFont.body)
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: {
                RNFHaptics.buttonTap()
                onContinue()
            }) {
                Text(tier.buttonLabel)
                    .font(RNFFont.bodyBold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)

            Spacer(minLength: 24)

        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .navigationTitle("Today's Progress")
        .navigationBarTitleDisplayMode(.inline)

    }

    // MARK: - Progress Card

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(index < completed ? tier.accentColor : Color(.tertiarySystemFill))
                        .frame(width: 28, height: 28)
                        .overlay {
                            if index < completed {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                }
                Spacer()
            }

            Text("\(completed) of \(total) habits completed")
                .font(RNFFont.caption)
                .foregroundStyle(Color.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Tier Logic

    private var tier: SuccessTier {
        guard total > 0 else { return .quarter }
        let ratio = Double(completed) / Double(total)
        switch ratio {
        case 1.0:
            return .full
        case 0.75...:
            return .threeQuarter
        case 0.5...:
            return .half
        default:
            return .quarter
        }
    }

}

// MARK: - Success Tiers

private enum SuccessTier {
    case quarter, half, threeQuarter, full

    var overline: String {
        switch self {
        case .quarter: return "A SPARK"
        case .half: return "HALFWAY THERE"
        case .threeQuarter: return "NEARLY FORGED"
        case .full: return "FULLY FORGED"
        }
    }

    var headline: String {
        switch self {
        case .quarter: return "Every Step Counts"
        case .half: return "The Forge Glows Brighter"
        case .threeQuarter: return "Almost Perfect"
        case .full: return "The Forge Burns Bright"
        }
    }

    var narrative: String {
        switch self {
        case .quarter:
            return "You showed up. That alone separates you from yesterday's version. One habit completed means the flame still lives."
        case .half:
            return "Half your goals met - that's momentum building. The Forge doesn't demand perfection. It demands presence."
        case .threeQuarter:
            return "So close to a perfect day. What you accomplished today would have been unthinkable a month ago. Honour the progress."
        case .full:
            return "Every single habit, completed. Today you weren't just consistent - you were relentless. The Forge bows to your discipline."
        }
    }

    var detail: String? {
        switch self {
        case .quarter:
            return "Tomorrow, try for two. Small steps compound into transformations."
        case .half:
            return "You're building the muscle of consistency. Keep this pace and growth is inevitable."
        case .threeQuarter:
            return nil
        case .full:
            return nil
        }
    }

    var buttonLabel: String {
        switch self {
        case .quarter: return "Small wins matter"
        case .half: return "Keep building"
        case .threeQuarter: return "Almost there"
        case .full: return "Forge on"
        }
    }

    var accentColor: Color {
        switch self {
        case .quarter: return .orange
        case .half: return .yellow
        case .threeQuarter: return .blue
        case .full: return .green
        }
    }
}

#Preview("1/4") {
    NavigationStack {
        GraduatedSuccessView(completed: 1, total: 4)
    }
}

#Preview("4/4") {
    NavigationStack {
        GraduatedSuccessView(completed: 4, total: 4)
    }
}
