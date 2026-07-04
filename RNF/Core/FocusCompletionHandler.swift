import Foundation

/// Handles Focus session completion by routing XP updates through
/// the profile → gameState.apply path for consistency with other engines.
struct FocusCompletionHandler {

    /// Completes a focus session, awarding XP and stat gains through the profile.
    @MainActor
    static func complete(xp: Int, gameState: GameState) {
        var updatedProfile = gameState.profile

        // Apply XP to profile
        updatedProfile.xp_total += xp
        let levelState = XPSystem.levelState(for: updatedProfile.xp_total)
        updatedProfile.level = levelState.level

        // Apply stat gains (Focus + Mind)
        updatedProfile.focus += 1
        updatedProfile.mind += 1

        // Route through the standard apply path
        gameState.apply(
            profile: updatedProfile,
            levelState: levelState,
            titles: gameState.titles,
            quests: gameState.quests,
            dailyGoal: gameState.dailyGoal,
            dailyCompleted: gameState.dailyCompleted,
            completedHabitIDs: gameState.completedHabitIDs,
            dailyLog: gameState.dailyLog
        )
    }
}
