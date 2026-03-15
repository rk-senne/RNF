import Foundation

struct XPSystem {

    static func applyXP(
        currentXP: Int,
        gainedXP: Int,
        levelXP: Int,
        currentLevel: Int
    ) -> (xp: Int, level: Int, leveledUp: Bool) {

        var xp = currentXP + gainedXP
        var level = currentLevel
        var leveledUp = false

        if xp >= levelXP {
            xp -= levelXP
            level += 1
            leveledUp = true
        }

        return (xp, level, leveledUp)
    }

}
