import Foundation
import os

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
    private weak var gameState: GameState?
    private var isProcessing = false

    init(
        dailyLogService: DailyLogService = DailyLogService(),
        xpService: XPService = XPService(),
        questService: QuestService = QuestService(),
        skillTreeService: SkillTreeService = SkillTreeService(),
        analyticsService: AnalyticsService = AnalyticsService()
    ) {
        self.dailyLogService = dailyLogService
        self.xpService = xpService
        self.questService = questService
        self.skillTreeService = skillTreeService
        self.analyticsService = analyticsService
    }

    func configure(gameState: GameState) {
        self.gameState = gameState
    }

    func processHabitCompletion(habitId: UUID) async -> ProgressionResult? {

        guard !isProcessing else { return nil }
        isProcessing = true
        defer { isProcessing = false }

        guard
            let gameState,
            let habit = gameState.quests.first(where: { $0.id == habitId }),
            !gameState.completedHabitIDs.contains(habitId)
        else {
            return nil
        }

        let completionDate = Date()
        let dailyGoal = gameState.dailyGoal
        var updatedCompletedHabitIDs = gameState.completedHabitIDs
        updatedCompletedHabitIDs.insert(habit.id)

        var updatedProfile = gameState.profile
        let previousStreak = updatedProfile.streak

        let todayLog: DailyLog
        do {
            todayLog = try await dailyLogService.getTodayLog(
                for: updatedProfile,
                dailyGoal: dailyGoal
            )
        } catch {
            RNFLogger.habitCompletion.error("ProgressionEngine.processHabitCompletion failed: \(error.localizedDescription)")
            return nil
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

        let updatedDailyCompleted = gameState.dailyCompleted + 1
        let missionCompleted =
            gameState.dailyCompleted < dailyGoal &&
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
            date: completionDate.startOfDay,
            xp_awarded: awardedXP
        )

        if !updatedProfile.isPlaceholder {
            do {
                guard let recordedCompletion = try await dailyLogService.recordHabitCompletion(completion) else {
                    return nil
                }

                // Chaos #9 fix: If backend returns an existing completion (dedup),
                // treat it as success — the completion exists, mission accomplished.
                if recordedCompletion.id != completion.id {
                    RNFLogger.habitCompletion.info("Dedup: existing completion \(recordedCompletion.id) used instead of \(completion.id)")
                }
            } catch {
                RNFLogger.habitCompletion.error("ProgressionEngine recordHabitCompletion failed: \(error.localizedDescription)")
                return nil
            }
        }

        var updatedDailyLog = todayLog
        updatedDailyLog.user_id = updatedProfile.isPlaceholder ? nil : updatedProfile.id
        updatedDailyLog.date = completionDate.startOfDay
        updatedDailyLog.habits_completed = updatedDailyCompleted
        updatedDailyLog.habits_required = dailyGoal
        updatedDailyLog.xp_earned += awardedXP
        updatedDailyLog.status = missionCompleted ? .complete : .partial

        await dailyLogService.saveDailyLog(updatedDailyLog)

        if !updatedProfile.isPlaceholder {
            do {
                if let persistedDailyLog = try await dailyLogService.updateStatus(
                    userId: updatedProfile.id,
                    date: completionDate
                ) {
                    updatedDailyLog = persistedDailyLog
                }
            } catch {
                RNFLogger.habitCompletion.error("ProgressionEngine updateStatus failed: \(error.localizedDescription)")
                return nil
            }
        }

        await dailyLogService.saveProfile(updatedProfile)

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
        AnalyticsTimestamp.string(for: date)
    }

}
