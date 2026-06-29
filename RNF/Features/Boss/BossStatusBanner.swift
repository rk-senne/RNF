import SwiftUI

struct BossStatusBanner: View {
    let boss: Boss?
    let isUnlocked: Bool

    var body: some View {
        if isUnlocked, let boss, !boss.isDefeated {
            HStack(spacing: 12) {
                Image(systemName: "shield.fill")
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text(boss.bossType.rawValue.capitalized)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Text("\(boss.currentHP)/\(boss.maxHP) HP")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ProgressView(value: boss.hpProgress)
                    .frame(width: 60)
                    .tint(.red)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(.secondarySystemBackground)))
        }
    }
}
