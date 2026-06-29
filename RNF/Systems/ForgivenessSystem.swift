import Foundation

struct ForgivenessSystem {

    struct Evaluation: Equatable {
        let canUseForgiveness: Bool
        let remainingTokens: Int
        let preservedStreak: Int
        let status: DailyLog.Status
    }

    static func evaluate(
        dailyLog: DailyLog,
        forgivenessTokens: Int,
        currentStreak: Int
    ) -> Evaluation {

        // Chaos #2: Don't waste a token preserving a 0-streak
        let canUseForgiveness = forgivenessTokens > 0
            && dailyLog.status == .missed
            && !dailyLog.forgiveness_used
            && currentStreak > 0

        return Evaluation(
            canUseForgiveness: canUseForgiveness,
            remainingTokens: canUseForgiveness ? forgivenessTokens - 1 : forgivenessTokens,
            preservedStreak: currentStreak,
            status: canUseForgiveness ? .forgiven : dailyLog.status
        )
    }

}
