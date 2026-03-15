import SwiftUI

struct RNFAnimation {

    static let xp = Animation.easeInOut(duration: 0.4)

    static let radar = Animation.spring(
        response: 0.6,
        dampingFraction: 0.7
    )

    static let aura = Animation
        .easeInOut(duration: 2)
        .repeatForever(autoreverses: true)
}
