import Foundation
import os

@MainActor
final class BossEngine {

    private let bossService: BossService
    private let achievementService: AchievementService
    private let xpService: XPService

    init(
        bossService: BossService = BossService(),
        achievementService: AchievementService = AchievementService(),
        xpService: XPService = XPService()
    ) {
        self.bossService = bossService
        self.achievementService = achievementService
        self.xpService = xpService
    }

    struct DamageResult {
        let boss: Boss
        let damageDealt: Int
        let defeated: Bool
        let xpReward: Int
    }

    func dealDamage(userId: UUID, source: DamageSource, level: Int, streak: Int) async -> DamageResult? {
        guard FeatureGate.isUnlocked(.bossChallenge, level: level, streak: streak, hasCompletedChallenge: false) else {
            return nil
        }

        do {
            guard let boss = try await bossService.activeBoss(userId: userId) else {
                return nil
            }

            let damage = source.damage
            let updated = try await bossService.dealDamage(bossId: boss.id, damage: damage)
            let xpReward = updated.isDefeated ? BossSystem.defeatReward(bossLevel: level) : 0

            RNFLogger.challenge.info("Boss damage: \(damage), defeated: \(updated.isDefeated)")

            return DamageResult(
                boss: updated,
                damageDealt: damage,
                defeated: updated.isDefeated,
                xpReward: xpReward
            )
        } catch {
            RNFLogger.challenge.error("BossEngine.dealDamage failed: \(error.localizedDescription)")
            return nil
        }
    }

    func spawnIfNeeded(userId: UUID, profile: Profile) async -> Boss? {
        guard FeatureGate.isUnlocked(.bossChallenge, level: profile.level, streak: profile.streak, hasCompletedChallenge: false) else {
            return nil
        }

        do {
            if let _ = try await bossService.activeBoss(userId: userId) {
                return nil
            }
            let type = BossSystem.selectBossType(for: profile.stats)
            let boss = try await bossService.spawnBoss(userId: userId, type: type, level: profile.level)
            // P20-VOX-03: Voice trigger for boss spawn
            ForgeVoice.speak("A new challenge approaches. Prepare yourself.")
            return boss
        } catch {
            RNFLogger.challenge.error("BossEngine.spawnIfNeeded failed: \(error.localizedDescription)")
            return nil
        }
    }

    enum DamageSource {
        case habitCompletion
        case workoutCompletion
        case readingCompletion
        case dailyComplete

        var damage: Int {
            switch self {
            case .habitCompletion: return BossSystem.damagePerHabit
            case .workoutCompletion: return BossSystem.damagePerWorkout
            case .readingCompletion: return BossSystem.damagePerReading
            case .dailyComplete: return BossSystem.damagePerDailyComplete
            }
        }
    }
}
