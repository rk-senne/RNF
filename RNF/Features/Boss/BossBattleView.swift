import SwiftUI

struct BossBattleView: View {
    let boss: Boss
    var onDealDamage: (() -> Void)?

    private var bossLoreDescription: String {
        switch boss.bossType {
        case .procrastination:
            return "It doesn't kill you. It delays you until you forget you were ever alive."
        case .doubt:
            return "It whispers: 'Is this even working?' It hopes you listen."
        case .laziness:
            return "You stopped growing. You didn't notice. That's how it wins."
        case .distraction:
            return "You're good enough. Why push? Why risk? Why change?"
        case .apathy:
            return "It needs nothing from you. That's why it's dangerous."
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text(boss.bossType.rawValue.capitalized)
                    .font(RNFFont.titleMedium)

                Text(bossLoreDescription)
                    .font(RNFFont.body)
                    .italic()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

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
                    .font(RNFFont.body)
                    .foregroundStyle(.secondary)
            }

            if boss.isDefeated {
                Label("Defeated!", systemImage: "trophy.fill")
                    .font(RNFFont.section)
                    .foregroundStyle(.yellow)
            } else {
                Text("Complete habits to deal damage")
                    .font(RNFFont.caption)
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
