import Foundation
import OSLog

struct ProgressionResult {

    let habit: Habit
    let updatedProfile: Profile
    let updatedDailyLog: DailyLog
    let questPlan: DailyQuestPlan
    let completedHabitIDs: Set<UUID>
    let xpGained: Int
    let levelState: XPSystem.LevelState
    let leveledUp: Bool
    let missionCompleted: Bool
    let unlockedBadge: String?

}

@MainActor
final class ProgressionEngine {

    private let dailyLogService: DailyLogService
    private let xpService: XPService
    private let questService: QuestService
    private let skillTreeService: SkillTreeService
    private let analyticsService: AnalyticsService
    private let calendar: Calendar
    private weak var gameState: GameState?

    init(
        dailyLogService: DailyLogService = DailyLogService(),
        xpService: XPService = XPService(),
        questService: QuestService = QuestService(),
        skillTreeService: SkillTreeService = SkillTreeService(),
        analyticsService: AnalyticsService = AnalyticsService(),
        calendar: Calendar = .current
    ) {
        self.dailyLogService = dailyLogService
        self.xpService = xpService
        self.questService = questService
        self.skillTreeService = skillTreeService
        self.analyticsService = analyticsService
        self.calendar = calendar
    }

    func configure(gameState: GameState) {
        self.gameState = gameState
    }

    func processHabitCompletion(habitId: UUID) async -> ProgressionResult? {

        guard let gameState else {
            RNFLogger.habitCompletion.info("operation=process_habit_completion result=skipped reason=unavailable_or_duplicate")
            return nil
        }

        return await processHabitCompletion(
            habitId: habitId,
            input: ProgressionInput(gameState: gameState)
        )

    }

    func processHabitCompletion(
        habitId: UUID,
        input: ProgressionInput
    ) async -> ProgressionResult? {

        guard
            let habit = input.quests.first(where: { $0.id == habitId }),
            !input.completedHabitIDs.contains(habitId)
        else {
            RNFLogger.habitCompletion.info("operation=process_habit_completion result=skipped reason=unavailable_or_duplicate")
            return nil
        }

        let completionDate = Date()
        let dailyGoal = input.dailyGoal
        var updatedCompletedHabitIDs = input.completedHabitIDs
        updatedCompletedHabitIDs.insert(habit.id)

        var updatedProfile = input.profile
        let previousStreak = updatedProfile.streak

        let todayLog: DailyLog
        if updatedProfile.isPlaceholder {
            todayLog = input.dailyLog
        } else {
            do {
                todayLog = try await dailyLogService.getTodayLog(
                    for: updatedProfile,
                    dailyGoal: dailyGoal
                )
            } catch {
                RNFLogger.dailyLog.error("operation=process_habit_completion result=failure step=get_today_log error_category=\(RNFLogger.errorCategory(error), privacy: .public)")
                return nil
            }
        }

        let activePerks = (try? await skillTreeService.activePerks(for: updatedProfile)) ?? .empty
        var updatedStats = updatedProfile.stats
        StatSystem.applyReward(
            stats: &updatedStats,
            for: habit.name,
            activePerks: activePerks
        )
        updatedProfile.stats = updatedStats

        let awardedXP = PerkSystem.modifiedXPReward(
            baseXP: habit.xpReward,
            activePerks: activePerks,
            currentDailyXP: todayLog.xp_earned
        )

        let xpState = xpService.awardXP(
            currentTotal: updatedProfile.xp_total,
            gainedXP: awardedXP
        )

        updatedProfile.xp_total = xpState.totalXP
        updatedProfile.level = xpState.level

        let updatedDailyCompleted = input.dailyCompleted + 1
        let missionCompleted =
            input.dailyCompleted < dailyGoal &&
            updatedDailyCompleted >= dailyGoal

        if missionCompleted {
            updatedProfile.streak = StreakSystem.updateStreak(
                currentStreak: updatedProfile.streak,
                dailyCompleted: updatedDailyCompleted,
                dailyGoal: dailyGoal
            )
        }

        let unlockedBadge = missionCompleted
            ? BadgeSystem.badge(for: updatedProfile.streak)
            : nil

        let completion = HabitCompletion(
            id: UUID(),
            user_id: updatedProfile.isPlaceholder ? nil : updatedProfile.id,
            habit_id: habit.id,
            completed_at: completionDate,
            date: DayBoundaryPolicy.normalizedDay(
                for: completionDate,
                calendar: calendar
            ),
            xp_awarded: awardedXP
        )

        if !updatedProfile.isPlaceholder {
            do {
                guard let recordedCompletion = try await dailyLogService.recordHabitCompletion(completion) else {
                    RNFLogger.habitCompletion.error("operation=process_habit_completion result=failure step=record_completion error_category=not_recorded")
                    return nil
                }

                guard recordedCompletion.id == completion.id else {
                    RNFLogger.habitCompletion.info("operation=process_habit_completion result=duplicate_existing")
                    return nil
                }
            } catch {
                RNFLogger.habitCompletion.error("operation=process_habit_completion result=failure step=record_completion error_category=\(RNFLogger.errorCategory(error), privacy: .public)")
                return nil
            }
        }

        var updatedDailyLog = todayLog
        updatedDailyLog.user_id = updatedProfile.isPlaceholder ? nil : updatedProfile.id
        updatedDailyLog.date = DayBoundaryPolicy.normalizedDay(
            for: completionDate,
            calendar: calendar
        )
        updatedDailyLog.habits_completed = updatedDailyCompleted
        updatedDailyLog.habits_required = dailyGoal
        updatedDailyLog.xp_earned += awardedXP
        updatedDailyLog.status = missionCompleted ? .complete : .partial

        let dailyLogSaveResult = await dailyLogService.saveDailyLog(updatedDailyLog)
        if !updatedProfile.isPlaceholder, !dailyLogSaveResult.savedRemotely {
            RNFLogger.dailyLog.error("operation=process_habit_completion result=failure step=save_daily_log error_category=\(String(describing: dailyLogSaveResult.error), privacy: .public)")
            return nil
        }

        if !updatedProfile.isPlaceholder {
            do {
                if let persistedDailyLog = try await dailyLogService.updateStatus(
                    userId: updatedProfile.id,
                    date: completionDate
                ) {
                    updatedDailyLog = persistedDailyLog
                }
            } catch {
                RNFLogger.dailyLog.error("operation=process_habit_completion result=failure step=update_status error_category=\(RNFLogger.errorCategory(error), privacy: .public)")
                return nil
            }
        }

        let profileSaveResult = await dailyLogService.saveProfile(updatedProfile)
        if !updatedProfile.isPlaceholder, !profileSaveResult.savedRemotely {
            RNFLogger.sync.error("operation=process_habit_completion result=failure step=save_profile error_category=\(String(describing: profileSaveResult.error), privacy: .public)")
            return nil
        }

        let questPlan = questService.updateQuestProgress(
            for: updatedProfile,
            activePerks: activePerks
        )
        updatedDailyLog.habits_required = questPlan.dailyGoal
        let levelState = xpService.levelState(for: updatedProfile.xp_total)

        if !updatedProfile.isPlaceholder {
            await analyticsService.trackEvent(
                .habitCompleted,
                properties: [
                    "user_id": updatedProfile.id.uuidString,
                    "habit_id": habit.id.uuidString,
                    "habit_name": habit.name,
                    "xp_awarded": "\(awardedXP)",
                    "timestamp": Self.analyticsTimestamp(for: completionDate)
                ]
            )

            if missionCompleted {
                await analyticsService.trackEvent(
                    .dailyGoalCompleted,
                    properties: [
                        "user_id": updatedProfile.id.uuidString,
                        "habits_completed": "\(updatedDailyCompleted)",
                        "daily_goal": "\(dailyGoal)",
                        "timestamp": Self.analyticsTimestamp(for: completionDate)
                    ]
                )
            }

            if updatedProfile.streak > previousStreak {
                await analyticsService.trackEvent(
                    .streakIncreased,
                    properties: [
                        "user_id": updatedProfile.id.uuidString,
                        "new_streak_length": "\(updatedProfile.streak)",
                        "timestamp": Self.analyticsTimestamp(for: completionDate)
                    ]
                )
            }

            if xpState.leveledUp {
                await analyticsService.trackEvent(
                    .levelUp,
                    properties: [
                        "user_id": updatedProfile.id.uuidString,
                        "new_level": "\(updatedProfile.level)",
                        "xp_total": "\(updatedProfile.xp_total)",
                        "timestamp": Self.analyticsTimestamp(for: completionDate)
                    ]
                )
            }
        }

        RNFLogger.habitCompletion.info("operation=process_habit_completion result=success mission_completed=\(missionCompleted, privacy: .public)")

        return ProgressionResult(
            habit: habit,
            updatedProfile: updatedProfile,
            updatedDailyLog: updatedDailyLog,
            questPlan: questPlan,
            completedHabitIDs: updatedCompletedHabitIDs,
            xpGained: awardedXP,
            levelState: levelState,
            leveledUp: xpState.leveledUp,
            missionCompleted: missionCompleted,
            unlockedBadge: unlockedBadge
        )

    }

    private static func analyticsTimestamp(for date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

}
