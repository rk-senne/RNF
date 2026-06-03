import Foundation

struct ForgivenessResult {
    let dailyLog: DailyLog
    let remainingTokens: Int
    let preservedStreak: Int
}

@MainActor
final class ChallengeEngine {

    private let challengeService: ChallengeService
    private let dailyLogService: DailyLogService
    private let userService: UserService
    private let skillTreeService: SkillTreeService
    private let calendar: Calendar
    private let analyticsService: AnalyticsService

    init(
        challengeService: ChallengeService = ChallengeService(),
        dailyLogService: DailyLogService = DailyLogService(),
        userService: UserService = UserService(),
        skillTreeService: SkillTreeService = SkillTreeService(),
        calendar: Calendar = .current,
        analyticsService: AnalyticsService = AnalyticsService()
    ) {
        self.challengeService = challengeService
        self.dailyLogService = dailyLogService
        self.userService = userService
        self.skillTreeService = skillTreeService
        self.calendar = calendar
        self.analyticsService = analyticsService
    }

    func loadActiveChallenge(userId: UUID) async -> Challenge? {
        do {
            return try await challengeService.getActiveChallenge(userId: userId)
        } catch {
            return nil
        }
    }

    func advanceIfDayComplete(userId: UUID, date: Date = Date()) async -> Challenge? {
        guard
            let challenge = await loadActiveChallenge(userId: userId),
            canAdvance(challenge, on: date)
        else {
            return nil
        }

        do {
            guard
                let dailyLog = try await dailyLogService.updateStatus(userId: userId, date: date),
                dailyLog.status == .complete
            else {
                return nil
            }

            if challenge.isFinalDay {
                return try await challengeService.completeChallenge(challengeId: challenge.id)
            }

            return try await challengeService.advanceDay(challenge)
        } catch {
            return nil
        }
    }

    func useForgiveness(
        userId: UUID,
        date: Date = Date(),
        currentStreak: Int
    ) async -> ForgivenessResult? {

        do {
            guard let dailyLog = try await dailyLogService.updateStatus(userId: userId, date: date) else {
                return nil
            }

            let tokens = try await userService.fetchForgivenessTokens(userId: userId)
            let activePerks = tokens > 0
                ? .empty
                : await activePerksForForgiveness(userId: userId)
            let availableProtection = tokens + activePerks.streakProtectionCount
            let evaluation = ForgivenessSystem.evaluate(
                dailyLog: dailyLog,
                forgivenessTokens: availableProtection,
                currentStreak: currentStreak
            )

            guard evaluation.canUseForgiveness else {
                return nil
            }

            let usesStoredToken = tokens > 0
            let remainingTokens = usesStoredToken
                ? try await userService.decrementForgivenessTokens(userId: userId)
                : tokens
            var forgivenLog = dailyLog
            forgivenLog.forgiveness_used = true
            forgivenLog.status = evaluation.status

            let saveResult = await dailyLogService.saveDailyLog(forgivenLog)
            guard saveResult.savedRemotely else {
                return nil
            }

            await analyticsService.trackEvent(
                usesStoredToken ? .forgivenessUsed : .streakProtectionApplied,
                properties: [
                    "user_id": userId.uuidString,
                    "streak_length": "\(evaluation.preservedStreak)",
                    "timestamp": Self.analyticsTimestamp(for: date)
                ]
            )

            return ForgivenessResult(
                dailyLog: forgivenLog,
                remainingTokens: remainingTokens,
                preservedStreak: evaluation.preservedStreak
            )
        } catch {
            return nil
        }
    }

    private func activePerksForForgiveness(userId: UUID) async -> ActivePerkSummary {
        do {
            async let skillNodes = skillTreeService.fetchSkillNodes()
            async let unlockedSkills = skillTreeService.fetchUserUnlocks(userId: userId)

            return try await PerkSystem.activePerks(
                skillNodes: skillNodes,
                unlockedSkills: unlockedSkills
            )
        } catch {
            return .empty
        }
    }

    func restartChallenge(_ challenge: Challenge, startDate: Date = Date()) async -> Challenge? {
        do {
            return try await challengeService.restartChallenge(challenge, startDate: startDate)
        } catch {
            return nil
        }
    }

    private func canAdvance(_ challenge: Challenge, on date: Date) -> Bool {
        let startDate = calendar.startOfDay(for: challenge.start_date)
        let targetDate = calendar.startOfDay(for: date)
        let elapsedDays = calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? 0
        let expectedDay = min(max(elapsedDays + 1, 1), Challenge.totalDays)
        return challenge.normalizedCurrentDay <= expectedDay
    }

    private static func analyticsTimestamp(for date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

}
