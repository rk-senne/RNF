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

        let canUseForgiveness = forgivenessTokens > 0
            && dailyLog.status == .missed
            && !dailyLog.forgiveness_used

        return Evaluation(
            canUseForgiveness: canUseForgiveness,
            remainingTokens: canUseForgiveness ? forgivenessTokens - 1 : forgivenessTokens,
            preservedStreak: currentStreak,
            status: canUseForgiveness ? .forgiven : dailyLog.status
        )
    }

}
