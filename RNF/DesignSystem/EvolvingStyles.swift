import SwiftUI

// P20-EXP-06b: Evolving surface modifier — subtle visual evolution as user levels up
struct EvolvingSurfaceModifier: ViewModifier {
    @EnvironmentObject private var evolution: UIEvolutionProvider
    @State private var shimmerPhase: CGFloat = 0
    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if evolution.state.borderGlow {
                        RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                            .strokeBorder(
                                evolution.state.accentColor.opacity(0.3),
                                lineWidth: 1
                            )
                    }
                }
            )
            .overlay(
                Group {
                    if shouldShimmer && !reduceMotion {
                        GeometryReader { geo in
                            LinearGradient(
                                colors: [.clear, evolution.state.accentColor.opacity(0.06), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: geo.size.width * 0.4)
                            .offset(x: shimmerPhase * geo.size.width * 1.4 - geo.size.width * 0.2)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous))
                        .allowsHitTesting(false)
                    }
                }
            )
            .onAppear {
                guard shouldShimmer && !reduceMotion else { return }
                withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                    shimmerPhase = 1
                }
            }
    }

    private var shouldShimmer: Bool {
        switch evolution.state {
        case .ascendant, .warlord, .apex: return true
        default: return false
        }
    }
}

extension View {
    func evolvingSurface() -> some View {
        modifier(EvolvingSurfaceModifier())
    }
}
