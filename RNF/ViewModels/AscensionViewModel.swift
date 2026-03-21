import SwiftUI

final class AscensionViewModel {

    func levelColor(for level: Int) -> Color {

        switch level {
        case 1...4:
            return .yellow
        case 5...9:
            return .purple
        case 10...14:
            return .red
        case 15...19:
            return .blue
        default:
            return .white
        }

    }

    func rankTitle(for level: Int) -> String {

        switch level {
        case 1...4:
            return "Disciple"
        case 5...9:
            return "Awakened"
        case 10...14:
            return "Ascendant"
        case 15...19:
            return "Warlord"
        default:
            return "Apex"
        }

    }

    func radarValues(for stats: Stats) -> [Double] {

        let maxStat = 20.0

        return [
            Double(stats.strength) / maxStat,
            Double(stats.discipline) / maxStat,
            Double(stats.focus) / maxStat,
            Double(stats.energy) / maxStat,
            Double(stats.wisdom) / maxStat,
            Double(stats.mind) / maxStat,
            Double(stats.spirit) / maxStat
        ]

    }

}
