import Foundation

struct StreakSystem {

    static func updateStreak(
        currentStreak: Int,
        dailyCompleted: Int,
        dailyGoal: Int,
        dayMissed: Bool = false
    ) -> Int {

        if dayMissed { return 0 }

        if dailyCompleted >= dailyGoal {
            return currentStreak + 1
        }

        return currentStreak
    }

}
