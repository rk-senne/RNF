import SwiftUI

struct RNFToast: View {

    let toast: NotificationManager.Toast?

    var body: some View {
        if let toast {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(RNFFont.bodyBold)
                    .foregroundStyle(tint)

                Text(message)
                    .font(RNFFont.pill)
                    .foregroundStyle(RNFColors.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(RNFColors.borderSubtle, lineWidth: 1))
            .transition(.move(edge: .top).combined(with: .opacity))
            .padding(.top, 8)
        }
    }

    private var iconName: String {
        switch toast {
        case .xpGain: return "arrow.up.circle.fill"
        case .statGain: return "chart.bar.fill"
        case .discovery: return "sparkles"
        case .none: return ""
        }
    }

    private var message: String {
        switch toast {
        case .xpGain(let xp): return "+\(xp) XP"
        case .statGain(let stat, let value): return "+\(value) \(stat)"
        case .discovery(let name, let xp): return "\(name) +\(xp) XP"
        case .none: return ""
        }
    }

    private var tint: Color {
        switch toast {
        case .xpGain: return RNFColors.success
        case .statGain: return RNFColors.primary
        case .discovery: return Color(hex: "#D4AF37")
        case .none: return .clear
        }
    }
}
