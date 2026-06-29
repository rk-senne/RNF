import SwiftUI

struct BossBattleView: View {
    let boss: Boss
    var onDealDamage: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Text(boss.bossType.rawValue.capitalized)
                .font(.system(size: 28, weight: .bold, design: .rounded))

            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.2))
                        Capsule().fill(Color.red)
                            .frame(width: geo.size.width * (1 - boss.hpProgress))
                    }
                }
                .frame(height: 16)

                Text("\(boss.currentHP) / \(boss.maxHP) HP")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            if boss.isDefeated {
                Label("Defeated!", systemImage: "trophy.fill")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.yellow)
            } else {
                Text("Complete habits to deal damage")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(.secondarySystemBackground)))
        .padding()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Boss \(boss.bossType.rawValue), \(boss.currentHP) of \(boss.maxHP) HP remaining")
    }
}
