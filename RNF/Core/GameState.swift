import Foundation
import Combine

@MainActor
final class GameState: ObservableObject {

    @Published var profile: Profile = .placeholder
    @Published var level: Int = 1
    @Published var xp: Int = 0
    @Published var xpToNext: Int = 200
    @Published var streak: Int = 0
    @Published var stats: Stats = .baseline
    @Published var titles: [String] = []
    @Published var quests: [Habit] = []
    @Published var completedHabitIDs: Set<UUID> = []
    @Published var dailyCompleted: Int = 0
    @Published var dailyGoal: Int = 4
    @Published var dailyLog: DailyLog = .today(goal: 4)

    func apply(
        profile: Profile,
        levelState: XPSystem.LevelState,
        titles: [String],
        quests: [Habit],
        dailyGoal: Int,
        dailyCompleted: Int,
        completedHabitIDs: Set<UUID>,
        dailyLog: DailyLog
    ) {

        self.profile = profile
        self.level = levelState.level
        self.xp = levelState.xpIntoLevel
        self.xpToNext = levelState.xpToNext
        self.streak = profile.streak
        self.stats = profile.stats
        self.titles = titles
        self.quests = quests
        self.dailyGoal = dailyGoal
        self.dailyCompleted = dailyCompleted
        self.completedHabitIDs = completedHabitIDs
        self.dailyLog = dailyLog
    }

}
