import SwiftUI

struct ConfettiView: View {

    @State private var particles: [Particle] = []
    @State private var isActive = false
    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let color: Color
        let size: CGFloat
    }

    var body: some View {
        GeometryReader { geo in
            if !reduceMotion {
                Canvas { context, size in
                    for particle in particles {
                        let rect = CGRect(x: particle.x, y: particle.y, width: particle.size, height: particle.size)
                        context.fill(Path(ellipseIn: rect), with: .color(particle.color))
                    }
                }
                .onAppear { spawn(in: geo.size) }
            }
        }
        .allowsHitTesting(false)
    }

    private func spawn(in size: CGSize) {
        let colors: [Color] = [RNFColors.primary, RNFColors.success, RNFColors.warning, .orange, .pink]
        particles = (0..<40).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -size.height * 0.3...0),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...8)
            )
        }
        isActive = true
        animate(size: size)
    }

    private func animate(size: CGSize) {
        Task {
            let steps = 30
            for _ in 0..<steps {
                try? await Task.sleep(nanoseconds: 50_000_000)
                particles = particles.map { p in
                    var p = p
                    p.y += CGFloat.random(in: 8...16)
                    p.x += CGFloat.random(in: -3...3)
                    return p
                }
            }
            particles = []
        }
    }
}
