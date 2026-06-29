import Foundation
import os

/// Hooks into ProgressionEngine to evaluate and unlock achievements after state changes.
final class AchievementEngine {

    private let achievementService: AchievementService

    init(achievementService: AchievementService = AchievementService()) {
        self.achievementService = achievementService
    }

    func evaluateAndUnlock(userId: UUID, profile: Profile, stats: AchievementService.UserStats) async -> [Achievement] {
        guard FeatureGate.isUnlocked(.achievements, level: profile.level, streak: profile.streak, hasCompletedChallenge: false) else {
            return []
        }

        do {
            let alreadyUnlocked = Set(try await achievementService.fetchUnlocked(userId: userId))
            let eligible = achievementService.evaluate(profile: profile, stats: stats)
            let newlyEarned = eligible.filter { !alreadyUnlocked.contains($0.id) }

            for achievement in newlyEarned {
                try await achievementService.unlock(userId: userId, achievementId: achievement.id)
            }

            return newlyEarned
        } catch {
            RNFLogger.challenge.error("AchievementEngine.evaluateAndUnlock failed: \(error.localizedDescription)")
            return []
        }
    }
}
