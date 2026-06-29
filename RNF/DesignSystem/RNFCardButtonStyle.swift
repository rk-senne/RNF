import SwiftUI

struct RNFCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animationIfAllowed(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
