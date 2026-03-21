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
        let questPlan = questService.generateDailyHabits(for: profile)
        let dailyLog = await DailyLogService().getTodayLog(
            for: profile,
            dailyGoal: questPlan.dailyGoal
        )

        applyState(
            profile: profile,
            quests: questPlan.habits,
            dailyGoal: questPlan.dailyGoal,
            dailyCompleted: dailyLog.habits_completed,
            completedHabitIDs: [],
            dailyLog: dailyLog
        )

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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.animatedHabit = nil
        }

        guard let result = await progressionEngine.processHabitCompletion(habitId: habit.id) else {
            return
        }

        xpGained = result.habit.xpReward
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
        quests: [Habit],
        dailyGoal: Int,
        dailyCompleted: Int,
        completedHabitIDs: Set<UUID>,
        dailyLog: DailyLog
    ) {

        guard let gameState else {
            return
        }

        let levelState = xpService.levelState(for: profile.xp_total)

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

        let questPlan = questService.generateDailyHabits(for: gameState.profile)

        applyState(
            profile: gameState.profile,
            quests: questPlan.habits,
            dailyGoal: questPlan.dailyGoal,
            dailyCompleted: 0,
            completedHabitIDs: [],
            dailyLog: .today(
                userID: gameState.profile.isPlaceholder ? nil : gameState.profile.id,
                goal: questPlan.dailyGoal
            )
        )

    }

}
