import Foundation

struct XPSystem {

    struct LevelState {

        let totalXP: Int
        let level: Int
        let xpIntoLevel: Int
        let xpToNext: Int
        let leveledUp: Bool

    }

    private static let thresholds: [Int] = [
        0,
        200,
        450,
        800,
        1300,
        2000,
        2900,
        4000,
        5400,
        7000,
        9000,
        11500,
        14500,
        18000,
        22000,
        27000,
        33000,
        40000,
        48000,
        57000
    ]

    static func applyXP(totalXP: Int, gainedXP: Int) -> LevelState {

        let previous = levelState(for: totalXP)
        let current = levelState(for: max(totalXP + gainedXP, 0))

        return LevelState(
            totalXP: current.totalXP,
            level: current.level,
            xpIntoLevel: current.xpIntoLevel,
            xpToNext: current.xpToNext,
            leveledUp: current.level > previous.level
        )

    }

    static func levelState(for totalXP: Int) -> LevelState {

        let sanitizedXP = max(totalXP, 0)
        var level = 1

        while sanitizedXP >= totalXPRequired(for: level + 1) {
            level += 1
        }

        let currentFloor = totalXPRequired(for: level)
        let nextFloor = totalXPRequired(for: level + 1)

        return LevelState(
            totalXP: sanitizedXP,
            level: level,
            xpIntoLevel: sanitizedXP - currentFloor,
            xpToNext: max(nextFloor - currentFloor, 1),
            leveledUp: false
        )

    }

    static func totalXPRequired(for level: Int) -> Int {

        guard level > 1 else {
            return 0
        }

        if level <= thresholds.count {
            return thresholds[level - 1]
        }

        var total = thresholds.last ?? 57000

        for nextLevel in (thresholds.count + 1)...level {
            total += nextLevel * 1500
        }

        return total
    }

}
