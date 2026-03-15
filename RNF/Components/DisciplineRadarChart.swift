import SwiftUI

struct DisciplineRadarChart: View {

    var stats: [Double]

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

            ZStack {

                RadarGrid()

                RadarShape(values: stats)
                    .fill(Color.purple.opacity(0.4))

                RadarShape(values: stats)
                    .stroke(Color.purple, lineWidth: 2)

            }

        }
        .aspectRatio(1, contentMode: .fit)

    }
}

struct RadarGrid: View {

    var body: some View {

        GeometryReader { geo in

            let center = CGPoint(
                x: geo.size.width / 2,
                y: geo.size.height / 2
            )

            let radius = geo.size.width / 2

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
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)

        }

    }

}

struct RadarShape: Shape {

    var values: [Double]

    func path(in rect: CGRect) -> Path {

        let center = CGPoint(
            x: rect.midX,
            y: rect.midY
        )

        let radius = rect.width / 2

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


