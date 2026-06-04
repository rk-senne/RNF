import Foundation
import Combine

@MainActor
final class HabitsViewModel: ObservableObject {

    @Published var xpGained: Int?
    @Published var showLevelUp = false
    @Published var showMissionComplete = false
    @Published var showBadgeUnlocked = false
    @Published var unlockedBadge = ""
    @Published var animatedHabit: UUID?
    @Published var loadErrorMessage: String?
    @Published var completionErrorMessage: String?
    @Published var weeklyHabit: Habit?

    private let userService: UserService
    private let questService: QuestService
    private let xpService: XPService
    private let progressionEngine: ProgressionEngine
    private weak var gameState: GameState?
    private var isLoaded = false

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
    }

    func completeHabit(_ habit: Habit) async {

        guard
            let gameState,
            !gameState.completedHabitIDs.contains(habit.id)
        else {
            return
        }

        animatedHabit = habit.id
        completionErrorMessage = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.animatedHabit = nil
        }

        guard let result = await progressionEngine.processHabitCompletion(habitId: habit.id) else {
            completionErrorMessage = "We couldn't save that completion. Please try again."
            return
        }

        completionErrorMessage = nil
        applyState(
            profile: result.updatedProfile,
            levelState: result.levelState,
            quests: result.questPlan.habits,
            dailyGoal: result.questPlan.dailyGoal,
            dailyCompleted: result.updatedDailyLog.habits_completed,
            completedHabitIDs: result.completedHabitIDs,
            dailyLog: result.updatedDailyLog
        )

        xpGained = result.xpGained
        showLevelUp = result.leveledUp
        showMissionComplete = result.missionCompleted

        if let badge = result.unlockedBadge {
            unlockedBadge = badge
            showBadgeUnlocked = true
        } else {
            unlockedBadge = ""
            showBadgeUnlocked = false
        }
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

#if DEBUG
    func loadForTesting(gameState: GameState) async {
        self.gameState = gameState
        progressionEngine.configure(gameState: gameState)
    }
#endif

}
