import Foundation
import Combine
import UIKit

@MainActor
final class HabitsViewModel: ObservableObject {

    @Published var xpGained: Int?
    @Published var showLevelUp = false
    @Published var showMissionComplete = false
    @Published var showBadgeUnlocked = false
    @Published var unlockedBadge = ""
    @Published var animatedHabit: UUID?
    @Published var loadErrorMessage: String?
    @Published var persistenceError: RNFServiceError?
    @Published var weeklyHabit: Habit?
    @Published var comboCount: Int = 0

    private let userService: UserService
    private let questService: QuestService
    private let xpService: XPService
    private let progressionEngine: ProgressionEngine
    private weak var gameState: GameState?
    private var isLoaded = false
    private var lastCompletionTime: Date?

    init(
        userService: UserService? = nil,
        questService: QuestService? = nil,
        xpService: XPService? = nil,
        progressionEngine: ProgressionEngine? = nil
    ) {
        self.userService = userService ?? UserService()
        self.questService = questService ?? QuestService()
        self.xpService = xpService ?? XPService()
        self.progressionEngine = progressionEngine ?? ProgressionEngine()
    }

    func load(gameState: GameState) async {

        self.gameState = gameState
        progressionEngine.configure(gameState: gameState)

        guard !isLoaded else {
            resetDailyStateIfNeeded()
            return
        }

        let profile = await userService.loadProfile()
        let questPlan = questService.generateQuestPlan(for: profile)
        let dailyLog: DailyLog

        do {
            dailyLog = try await DailyLogService().getTodayLog(
                for: profile,
                dailyGoal: questPlan.daily.dailyGoal
            )
            loadErrorMessage = nil
        } catch {
            loadErrorMessage = error.localizedDescription
            return
        }

        applyState(
            profile: profile,
            quests: questPlan.daily.habits,
            dailyGoal: questPlan.daily.dailyGoal,
            dailyCompleted: dailyLog.habits_completed,
            completedHabitIDs: [],
            dailyLog: dailyLog
        )
        weeklyHabit = questPlan.weekly.habit

        isLoaded = true
        resetDailyStateIfNeeded()
    }

    func handleForegroundTransition() {
        resetDailyStateIfNeeded()
        if let gameState {
            WidgetDataWriter.shared.write(from: gameState)
        }
    }

    func completeHabit(_ habit: Habit, notifications: NotificationManager? = nil) async {

        guard
            let gameState,
            !gameState.completedHabitIDs.contains(habit.id)
        else {
            return
        }

        animatedHabit = habit.id

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.animatedHabit = nil
        }

        guard let result = await progressionEngine.processHabitCompletion(habitId: habit.id) else {
            persistenceError = .unknown
            RNFHaptics.warning()
            return
        }
        persistenceError = nil
        RNFHaptics.impact(.medium)

        // P20-EXP-05d: Detect tier-up
        let oldTier = StreakTierSystem.tier(for: gameState.streak)
        let newTier = StreakTierSystem.tier(for: result.updatedProfile.streak)
        let tierChanged = oldTier != newTier && result.missionCompleted

        applyState(
            profile: result.updatedProfile,
            levelState: result.levelState,
            quests: result.questPlan.habits,
            dailyGoal: result.questPlan.dailyGoal,
            dailyCompleted: result.updatedDailyLog.habits_completed,
            completedHabitIDs: result.completedHabitIDs,
            dailyLog: result.updatedDailyLog
        )

        // P20-EXP-09c: Save snapshot at streak milestones
        let newStreak = result.updatedProfile.streak
        if result.missionCompleted, [7, 14, 30, 60, 90].contains(newStreak) {
            let s = result.updatedProfile.stats
            MemoryService.save(ProgressSnapshot(
                milestone: "day\(newStreak)",
                dateString: Date().formatted("yyyy-MM-dd"),
                level: result.updatedProfile.level,
                streak: newStreak,
                xpTotal: result.updatedProfile.xp_total,
                stats: [
                    Double(s.strength), Double(s.discipline), Double(s.focus),
                    Double(s.energy), Double(s.wisdom), Double(s.mind), Double(s.spirit)
                ],
                tierName: newTier.rawValue
            ))
        }

        // Fire through notification system
        if let notifications {
            notifications.showToast(.xpGain(result.xpGained))

            if result.leveledUp {
                notifications.showCelebration(.levelUp(gameState.level))
                RNFHaptics.success()
            }

            if result.missionCompleted {
                notifications.showCelebration(.missionComplete)
                let streak = result.updatedProfile.streak
                if streak == 7 || streak == 14 || streak == 30 || streak == 60 || streak == 90 {
                    RNFHaptics.success()
                    // P20-VOX-03: Voice trigger for streak milestones
                    ForgeVoice.speak("\(streak) days. The discipline holds.")
                }
            }

            if let badge = result.unlockedBadge {
                notifications.showCelebration(.badgeUnlocked(badge))
            }

            // P20-EXP-05d: Fire tier-up celebration
            if tierChanged {
                notifications.showCelebration(.tierUp(newTier.rawValue))
                RNFHaptics.success()
            }
        } else {
            // Fallback for legacy callers
            xpGained = result.xpGained
            showLevelUp = result.leveledUp
            showMissionComplete = result.missionCompleted
            if let badge = result.unlockedBadge {
                unlockedBadge = badge
                showBadgeUnlocked = true
            }
        }

        WidgetDataWriter.shared.write(from: gameState)

        // P20-EXP-19c: Update Live Activity with current progress
        if #available(iOS 16.2, *) {
            let tierName = StreakTierSystem.tier(for: gameState.streak).rawValue
            if gameState.dailyCompleted >= gameState.dailyGoal {
                LiveActivityManager.end()
            } else {
                LiveActivityManager.update(
                    habitsCompleted: gameState.dailyCompleted,
                    habitsGoal: gameState.dailyGoal,
                    streak: gameState.streak,
                    tierName: tierName
                )
            }
        }

        // P20-EXP-02c: Combo detection
        if let last = lastCompletionTime, Date().timeIntervalSince(last) < 60 {
            comboCount += 1
            let comboBonus = 5 * comboCount
            notifications?.showToast(.xpGain(comboBonus))
        } else {
            comboCount = 1
        }
        lastCompletionTime = Date()
    }

    private func applyState(
        profile: Profile,
        levelState: XPSystem.LevelState? = nil,
        quests: [Habit],
        dailyGoal: Int,
        dailyCompleted: Int,
        completedHabitIDs: Set<UUID>,
        dailyLog: DailyLog
    ) {

        guard let gameState else {
            return
        }

        let levelState = levelState ?? xpService.levelState(for: profile.xp_total)

        gameState.apply(
            profile: profile,
            levelState: levelState,
            titles: BadgeSystem.titles(for: profile.streak),
            quests: quests,
            dailyGoal: dailyGoal,
            dailyCompleted: dailyCompleted,
            completedHabitIDs: completedHabitIDs,
            dailyLog: dailyLog
        )

    }

    private func resetDailyStateIfNeeded() {

        guard let gameState else {
            return
        }

        let today = Date().formatted("yyyy-MM-dd")
        let defaults = UserDefaults.standard
        let lastResetDate = defaults.string(forKey: "lastResetDate")

        guard lastResetDate != today else {
            return
        }

        defaults.set(today, forKey: "lastResetDate")

        let questPlan = questService.generateQuestPlan(for: gameState.profile)
        weeklyHabit = questPlan.weekly.habit

        applyState(
            profile: gameState.profile,
            quests: questPlan.daily.habits,
            dailyGoal: questPlan.daily.dailyGoal,
            dailyCompleted: 0,
            completedHabitIDs: [],
            dailyLog: .today(
                userID: gameState.profile.isPlaceholder ? nil : gameState.profile.id,
                goal: questPlan.daily.dailyGoal
            )
        )

    }

}
