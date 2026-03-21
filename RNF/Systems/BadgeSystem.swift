import Foundation

struct BadgeSystem {

    static func badge(for streak: Int) -> String? {

        switch streak {

        case 3:
            return "Ember Initiate"

        case 7:
            return "Forged Disciple"

        case 14:
            return "Iron Ascendant"

        case 30:
            return "Warlord of Discipline"

        case 90:
            return "Apex Being"

        default:
            return nil
        }

    }

    static func titles(for streak: Int) -> [String] {

        [3, 7, 14, 30, 90].compactMap { milestone in
            guard milestone <= streak else {
                return nil
            }

            return badge(for: milestone)
        }

    }

}
