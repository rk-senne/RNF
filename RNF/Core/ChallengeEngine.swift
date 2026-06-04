import Foundation
import OSLog

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
            let challenge = try await challengeService.getActiveChallenge(userId: userId)
            RNFLogger.challenge.info("operation=load_active_challenge result=\(challenge == nil ? "not_found" : "success", privacy: .public)")
            return challenge
        } catch {
            RNFLogger.challenge.error("operation=load_active_challenge result=failure error_category=\(RNFLogger.errorCategory(error), privacy: .public)")
            return nil
        }
    }

    func advanceIfDayComplete(userId: UUID, date: Date = Date()) async -> Challenge? {
        guard
            let challenge = await loadActiveChallenge(userId: userId),
            canAdvance(challenge, on: date)
        else {
            RNFLogger.challenge.info("operation=advance_if_day_complete result=skipped reason=no_active_or_not_ready")
            return nil
        }

        do {
            guard
                let dailyLog = try await dailyLogService.updateStatus(userId: userId, date: date),
                dailyLog.status == .complete
            else {
                RNFLogger.challenge.info("operation=advance_if_day_complete result=skipped reason=day_incomplete")
                return nil
            }

            if challenge.isFinalDay {
                let completedChallenge = try await challengeService.completeChallenge(challengeId: challenge.id)
                RNFLogger.challenge.info("operation=advance_if_day_complete result=completed")
                return completedChallenge
            }

            let advancedChallenge = try await challengeService.advanceDay(challenge)
            RNFLogger.challenge.info("operation=advance_if_day_complete result=advanced")
            return advancedChallenge
        } catch {
            RNFLogger.challenge.error("operation=advance_if_day_complete result=failure error_category=\(RNFLogger.errorCategory(error), privacy: .public)")
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
                RNFLogger.dailyLog.info("operation=use_forgiveness result=skipped reason=daily_log_not_found")
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
                RNFLogger.challenge.info("operation=use_forgiveness result=skipped reason=not_available")
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
                RNFLogger.dailyLog.error("operation=use_forgiveness result=failure step=save_daily_log error_category=\(String(describing: saveResult.error), privacy: .public)")
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

            RNFLogger.challenge.info("operation=use_forgiveness result=success")
            return ForgivenessResult(
                dailyLog: forgivenLog,
                remainingTokens: remainingTokens,
                preservedStreak: evaluation.preservedStreak
            )
        } catch {
            RNFLogger.challenge.error("operation=use_forgiveness result=failure error_category=\(RNFLogger.errorCategory(error), privacy: .public)")
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
            let restartedChallenge = try await challengeService.restartChallenge(challenge, startDate: startDate)
            RNFLogger.challenge.info("operation=restart_challenge_engine result=success")
            return restartedChallenge
        } catch {
            RNFLogger.challenge.error("operation=restart_challenge_engine result=failure error_category=\(RNFLogger.errorCategory(error), privacy: .public)")
            return nil
        }
    }

    private func canAdvance(_ challenge: Challenge, on date: Date) -> Bool {
        let startDate = DayBoundaryPolicy.normalizedDay(
            for: challenge.start_date,
            calendar: calendar
        )
        let targetDate = DayBoundaryPolicy.normalizedDay(
            for: date,
            calendar: calendar
        )
        let elapsedDays = calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? 0
        let expectedDay = min(max(elapsedDays + 1, 1), Challenge.totalDays)
        return challenge.normalizedCurrentDay <= expectedDay
    }

    private static func analyticsTimestamp(for date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

}
