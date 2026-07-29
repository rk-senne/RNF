import SwiftUI

/// Displays the shared bond streak with buddy as a growing flame.
/// Shows on home screen when user has an active buddy pair.
struct BondStreakView: View {

    let bondStreak: Int
    let buddyDidComplete: Bool

    private var flameSize: CGFloat {
        switch bondStreak {
        case 0...6: return 16
        case 7...13: return 20
        case 14...29: return 24
        case 30...59: return 28
        default: return 32
        }
    }

    private var flameColor: Color {
        switch bondStreak {
        case 0...6: return .orange.opacity(0.6)
        case 7...13: return .orange
        case 14...29: return .red
        case 30...59: return .purple
        default: return .yellow
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            // Shared flame icon that grows with streak
            Image(systemName: "flame.fill")
                .font(.system(size: flameSize))
                .foregroundStyle(flameColor)
                .symbolEffect(.pulse, isActive: buddyDidComplete)

            VStack(alignment: .leading, spacing: 0) {
                Text("\(bondStreak)")
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                Text("Bond")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Bond streak: \(bondStreak) days with your buddy")
    }
}
