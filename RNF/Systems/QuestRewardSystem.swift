import Foundation

struct QuestRewardSystem {

    static func rewards(for quest: String) -> [String:Int] {

        switch quest {

        case "Pushups":
            return [
                "strength": 5,
                "discipline": 3,
                "energy": 2
            ]

        case "Meditation":
            return [
                "mind": 4,
                "focus": 3,
                "spirit": 3
            ]

        case "Cold Shower":
            return [
                "discipline": 4,
                "energy": 3
            ]

        case "Reading":
            return [
                "wisdom": 5,
                "focus": 3
            ]

        default:
            return [
                "discipline": 2
            ]

        }

    }

}
