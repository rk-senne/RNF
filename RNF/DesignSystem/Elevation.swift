import SwiftUI

struct RNFShadow: ViewModifier {
    enum Level { case card, elevated }

    let level: Level

    func body(content: Content) -> some View {
        switch level {
        case .card:
            content.shadow(color: .black.opacity(0.06), radius: 24, x: 0, y: 12)
        case .elevated:
            content.shadow(color: .black.opacity(0.1), radius: 32, x: 0, y: 16)
        }
    }
}

extension View {
    func rnfShadow(_ level: RNFShadow.Level = .card) -> some View {
        modifier(RNFShadow(level: level))
    }
}
