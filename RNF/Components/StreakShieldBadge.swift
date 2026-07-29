import SwiftUI

/// Displays equipped streak shields with equip action.
/// Shows shield count and allows equipping new shields.
struct StreakShieldBadge: View {
    
    let equippedShields: Int
    let canEquip: Bool
    let onEquip: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<StreakShieldSystem.maxEquipped, id: \.self) { index in
                Image(systemName: index < equippedShields ? "shield.fill" : "shield")
                    .font(.caption)
                    .foregroundStyle(index < equippedShields ? Color.blue : Color.secondary.opacity(0.4))
            }
            
            if canEquip {
                Button(action: onEquip) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
                .accessibilityLabel("Equip streak shield")
                .accessibilityHint("Costs \(StreakShieldSystem.shieldCost) Forge Tokens")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(equippedShields) of \(StreakShieldSystem.maxEquipped) streak shields equipped")
    }
}
