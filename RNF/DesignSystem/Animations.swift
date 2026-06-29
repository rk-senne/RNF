import SwiftUI

extension View {
    /// Conditionally applies animation only when Reduce Motion is off.
    func animationIfAllowed(_ animation: Animation, value: some Equatable) -> some View {
        self.animation(UIAccessibility.isReduceMotionEnabled ? nil : animation, value: value)
    }
}
