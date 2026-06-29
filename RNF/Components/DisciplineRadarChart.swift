import SwiftUI

struct DisciplineRadarChart: View {

    var stats: [Double]
    @State private var animatedStats: [Double] = Array(repeating: 0, count: 7)
    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    let labels = [
        "Strength",
        "Discipline",
        "Focus",
        "Energy",
        "Wisdom",
        "Mind",
        "Spirit"
    ]

    var body: some View {

        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 * 0.75

            ZStack {
                RadarGrid()

                RadarShape(values: animatedStats)
                    .fill(
                        RadialGradient(
                            colors: [RNFColors.primary.opacity(0.15), RNFColors.primary.opacity(0.4)],
                            center: .center,
                            startRadius: 0,
                            endRadius: radius
                        )
                    )

                RadarShape(values: animatedStats)
                    .stroke(RNFColors.primary, lineWidth: 2)

                // Data point dots
                ForEach(0..<animatedStats.count, id: \.self) { i in
                    let angle = Double(i) * (2 * .pi / Double(animatedStats.count))
                    let length = radius * animatedStats[i]
                    Circle()
                        .fill(RNFColors.primary)
                        .frame(width: 6, height: 6)
                        .position(
                            x: center.x + CGFloat(cos(angle)) * length,
                            y: center.y + CGFloat(sin(angle)) * length
                        )
                }

                // Axis labels
                ForEach(0..<labels.count, id: \.self) { i in
                    let angle = Double(i) * (2 * .pi / Double(labels.count))
                    let labelRadius = radius * 1.2
                    Text(labels[i])
                        .font(RNFFont.caption)
                        .foregroundStyle(.secondary)
                        .position(
                            x: center.x + CGFloat(cos(angle)) * labelRadius,
                            y: center.y + CGFloat(sin(angle)) * labelRadius
                        )
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .onAppear {
            if reduceMotion {
                animatedStats = stats
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animatedStats = stats
                }
            }
        }
        .onChange(of: stats) { _, newStats in
            if reduceMotion {
                animatedStats = newStats
            } else {
                withAnimation(.spring(response: 0.5)) {
                    animatedStats = newStats
                }
            }
        }
    }

    private var accessibilitySummary: String {
        let pairs = zip(labels, stats).map { "\($0): \(Int($1 * 20))" }
        return "Stats chart. " + pairs.joined(separator: ", ")
    }
}

struct RadarGrid: View {

    var body: some View {

        GeometryReader { geo in

            let center = CGPoint(
                x: geo.size.width / 2,
                y: geo.size.height / 2
            )

            let radius = min(geo.size.width, geo.size.height) / 2 * 0.75

            Path { path in
                for i in 0..<7 {
                    let angle = Double(i) * (2 * Double.pi / 7)
                    let point = CGPoint(
                        x: center.x + CGFloat(cos(angle)) * radius,
                        y: center.y + CGFloat(sin(angle)) * radius
                    )
                    path.move(to: center)
                    path.addLine(to: point)
                }
            }
            .stroke(RNFColors.border, lineWidth: 1)

        }

    }

}

struct RadarShape: Shape {

    var values: [Double]

    var animatableData: [Double] {
        get { values }
        set { values = newValue }
    }

    func path(in rect: CGRect) -> Path {

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * 0.75

        var path = Path()

        for i in 0..<values.count {
            let angle = Double(i) * (2 * Double.pi / Double(values.count))
            let length = radius * values[i]
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * length,
                y: center.y + CGFloat(sin(angle)) * length
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }

}

extension Array: @retroactive VectorArithmetic where Element == Double {
    public static func - (lhs: [Double], rhs: [Double]) -> [Double] {
        zip(lhs, rhs).map { $0 - $1 }
    }
    public static func + (lhs: [Double], rhs: [Double]) -> [Double] {
        zip(lhs, rhs).map { $0 + $1 }
    }
    public mutating func scale(by rhs: Double) {
        self = map { $0 * rhs }
    }
    public var magnitudeSquared: Double {
        reduce(0) { $0 + $1 * $1 }
    }
    public static var zero: [Double] { [] }
}
