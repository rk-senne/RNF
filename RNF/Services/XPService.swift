import Foundation

final class XPService {

    func awardXP(currentTotal: Int, gainedXP: Int) -> XPSystem.LevelState {
        XPSystem.applyXP(totalXP: currentTotal, gainedXP: gainedXP)
    }

    func levelState(for totalXP: Int) -> XPSystem.LevelState {
        XPSystem.levelState(for: totalXP)
    }

    func totalXPRequired(for level: Int) -> Int {
        XPSystem.totalXPRequired(for: level)
    }

}
