import Foundation

struct StreakSystem {

    static func updateStreak(
        currentStreak: Int,
        dailyCompleted: Int,
        dailyGoal: Int
    ) -> Int {

        if dailyCompleted >= dailyGoal {
            return currentStreak + 1
        }

        return currentStreak
    }

}
