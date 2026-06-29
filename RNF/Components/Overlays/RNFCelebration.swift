import SwiftUI

struct RNFCelebration: View {

    let celebration: NotificationManager.Celebration?
    let onDismiss: () -> Void

    var body: some View {
        if let celebration {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { onDismiss() }

                VStack(spacing: 16) {
                    Image(systemName: iconName)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(tint)

                    Text(title)
                        .font(RNFFont.display)
                        .foregroundStyle(RNFColors.textPrimary)

                    Text(subtitle)
                        .font(RNFFont.section)
                        .foregroundStyle(RNFColors.textSecondary)
                }
                .padding(40)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous).strokeBorder(RNFColors.borderSubtle, lineWidth: 1))
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
            .transition(.opacity)
        }
    }

    private var iconName: String {
        switch celebration {
        case .levelUp: return "arrow.up.circle.fill"
        case .missionComplete: return "checkmark.seal.fill"
        case .badgeUnlocked: return "medal.fill"
        case .tierUp: return "flame.fill"
        case .none: return ""
        }
    }

    private var title: String {
        switch celebration {
        case .levelUp(let level): return "LEVEL \(level)"
        case .missionComplete: return "COMPLETE"
        case .badgeUnlocked(let badge): return badge
        case .tierUp(let tier): return tier.uppercased()
        case .none: return ""
        }
    }

    private var subtitle: String {
        switch celebration {
        case .levelUp: return "LEVEL UP"
        case .missionComplete: return "+50 XP BONUS"
        case .badgeUnlocked: return "BADGE UNLOCKED"
        case .tierUp: return "TIER UP"
        case .none: return ""
        }
    }

    private var tint: Color {
        switch celebration {
        case .levelUp: return RNFColors.warning
        case .missionComplete: return RNFColors.success
        case .badgeUnlocked: return RNFColors.primary
        case .tierUp: return RNFColors.warning
        case .none: return .clear
        }
    }
}
