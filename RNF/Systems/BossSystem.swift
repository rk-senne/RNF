import Foundation

enum BossSystem {

    /// Damage dealt per habit completion against active boss
    static let damagePerHabit = 1
    static let damagePerWorkout = 2
    static let damagePerReading = 1
    static let damagePerDailyComplete = 3

    /// Selects which boss to spawn based on user's weakest stat
    static func selectBossType(for stats: Stats) -> Boss.BossType {
        let statValues: [(Boss.BossType, Int)] = [
            (.laziness, stats.energy),
            (.procrastination, stats.discipline),
            (.doubt, stats.spirit),
            (.distraction, stats.focus),
            (.apathy, stats.mind)
        ]
        return statValues.min(by: { $0.1 < $1.1 })?.0 ?? .procrastination
    }

    /// Boss HP scales with user level
    static func bossHP(for level: Int) -> Int {
        10 + (level * 5)
    }

    /// XP reward for defeating a boss
    static func defeatReward(bossLevel: Int) -> Int {
        50 + (bossLevel * 10)
    }
}
