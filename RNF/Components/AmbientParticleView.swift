import SwiftUI

// P20-EXP-06d: Ambient particles at Apex evolution state
struct AmbientParticleView: View {
    @State private var particles: [EmberParticle] = []
    private let reduceMotion = UIAccessibility.isReduceMotionEnabled
    private let count = 15

    struct EmberParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
    }

    var body: some View {
        if !reduceMotion {
            GeometryReader { geo in
                Canvas { context, size in
                    for p in particles {
                        let rect = CGRect(x: p.x, y: p.y, width: 4, height: 4)
                        context.fill(Path(ellipseIn: rect), with: .color(Color(hex: "#D4AF37").opacity(0.3)))
                    }
                }
                .onAppear { startDrift(in: geo.size) }
            }
            .allowsHitTesting(false)
        }
    }

    private func startDrift(in size: CGSize) {
        particles = (0..<count).map { _ in
            EmberParticle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
        }
        drift(size: size)
    }

    private func drift(size: CGSize) {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000)
                particles = particles.map { p in
                    var p = p
                    p.y -= CGFloat.random(in: 1...2)
                    p.x += CGFloat.random(in: -0.5...0.5)
                    if p.y < 0 {
                        p.y = size.height
                        p.x = CGFloat.random(in: 0...size.width)
                    }
                    return p
                }
            }
        }
    }
}
