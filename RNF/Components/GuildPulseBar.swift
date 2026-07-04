import SwiftUI

// P20-EXP-10b: Guild pulse bar showing active guild members
struct GuildPulseBar: View {
    let membersActive: Int
    var body: some View {
        if membersActive > 0 {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(RNFFont.captionBoldSmall)
                    .foregroundStyle(RNFColors.quest)
                Text("\(membersActive) guild members active today")
                    .font(RNFFont.caption)
                    .foregroundStyle(RNFColors.textSecondary)
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(membersActive) guild members are active today")
        }
    }
}
