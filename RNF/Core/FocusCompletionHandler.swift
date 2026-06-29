import Foundation

// P20-EXP-13b: Wire Focus XP on session completion
struct FocusCompletionHandler {
    static func complete(xp: Int, gameState: GameState) {
        let applied = XPSystem.applyXP(totalXP: gameState.xp, gainedXP: xp)
        gameState.xp = applied.xpIntoLevel
        gameState.xpToNext = applied.xpToNext
        if applied.leveledUp { gameState.level = applied.level }
        gameState.stats.focus += 1
        gameState.stats.mind += 1
    }
}
