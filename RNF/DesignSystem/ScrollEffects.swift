import SwiftUI

extension View {
    @ViewBuilder
    func cardScrollEntrance() -> some View {
        if #available(iOS 17.0, *) {
            self.scrollTransition { content, phase in
                content
                    .opacity(phase.isIdentity ? 1 : 0.85)
                    .offset(y: phase.isIdentity ? 0 : 8)
            }
        } else {
            self
        }
    }
}
