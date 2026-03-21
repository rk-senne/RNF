import Foundation

struct ProgressionResult {

    let habit: Habit
    let leveledUp: Bool
    let missionCompleted: Bool
    let unlockedBadge: String?

}

@MainActor
final class ProgressionEngine {

    private let dailyLogService: DailyLogService
    private let xpService: XPService
    private let questService: QuestService
    private weak var gameState: GameState?

    init(
        dailyLogService: DailyLogService = DailyLogService(),
        xpService: XPService = XPService(),
        questService: QuestService = QuestService()
    ) {
        self.dailyLogService = dailyLogService
        self.xpService = xpService
        self.questService = questService
    }

    func configure(gameState: GameState) {
        self.gameState = gameState
    }

    func processHabitCompletion(habitId: UUID) async -> ProgressionResult? {

        guard
            let gameState,
            let habit = gameState.quests.first(where: { $0.id == habitId }),
            !gameState.completedHabitIDs.contains(habitId)
        else {
            return nil
        }

        let completionDate = Date()
        var updatedCompletedHabitIDs = gameState.completedHabitIDs
        updatedCompletedHabitIDs.insert(habit.id)

        var updatedProfile = gameState.profile
        var updatedStats = updatedProfile.stats
        StatSystem.applyReward(stats: &updatedStats, for: habit.name)
        updatedProfile.stats = updatedStats

        let xpState = xpService.awardXP(
            currentTotal: updatedProfile.xp_total,
            gainedXP: habit.xpReward
        )

        updatedProfile.xp_total = xpState.totalXP
        updatedProfile.level = xpState.level

        let updatedDailyCompleted = gameState.dailyCompleted + 1
        let missionCompleted =
            gameState.dailyCompleted < gameState.dailyGoal &&
            updatedDailyCompleted >= gameState.dailyGoal

        if missionCompleted {
            updatedProfile.streak = StreakSystem.updateStreak(
                currentStreak: updatedProfile.streak,
                dailyCompleted: updatedDailyCompleted,
                dailyGoal: gameState.dailyGoal
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
            xp_awarded: habit.xpReward
        )

        await dailyLogService.recordCompletion(completion)

        var updatedDailyLog = gameState.dailyLog
        updatedDailyLog.user_id = updatedProfile.isPlaceholder ? nil : updatedProfile.id
        updatedDailyLog.date = completionDate.startOfDay
        updatedDailyLog.habits_completed = updatedDailyCompleted
        updatedDailyLog.habits_required = gameState.dailyGoal
        updatedDailyLog.xp_earned += habit.xpReward
        updatedDailyLog.status = missionCompleted ? .complete : .partial

        await dailyLogService.saveDailyLog(updatedDailyLog)
        await dailyLogService.saveProfile(updatedProfile)

        let questPlan = questService.updateQuestProgress(for: updatedProfile)
        updatedDailyLog.habits_required = questPlan.dailyGoal

        gameState.apply(
            profile: updatedProfile,
            levelState: xpService.levelState(for: updatedProfile.xp_total),
            titles: BadgeSystem.titles(for: updatedProfile.streak),
            quests: questPlan.habits,
            dailyGoal: questPlan.dailyGoal,
            dailyCompleted: updatedDailyCompleted,
            completedHabitIDs: updatedCompletedHabitIDs,
            dailyLog: updatedDailyLog
        )

        return ProgressionResult(
            habit: habit,
            leveledUp: xpState.leveledUp,
            missionCompleted: missionCompleted,
            unlockedBadge: unlockedBadge
        )

    }

}
