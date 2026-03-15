import Foundation

struct QuestDifficultySystem {

    static func questsPerDay(for level: Int) -> Int {

        switch level {

        case 1...4:
            return 4

        case 5...9:
            return 6

        case 10...19:
            return 8

        case 20...29:
            return 10

        default:
            return 12
        }
    }

}
