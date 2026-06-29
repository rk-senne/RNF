import SwiftUI

/// P20-EXP-02a: Floating "+N XP" text that drifts up and fades out on completion.
struct FloatingXPText: View {

    let xp: Int
    let visible: Bool

    var body: some View {
        Text("+\(xp) XP")
            .font(RNFFont.pill)
            .foregroundStyle(RNFColors.success)
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : -30)
            .animationIfAllowed(.easeOut(duration: 0.6), value: visible)
    }
}
