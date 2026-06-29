import Foundation
import WidgetKit

final class WidgetDataWriter {

    static let shared = WidgetDataWriter()

    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = UserDefaults(suiteName: RNFWidgetData.appGroupID)) {
        self.defaults = defaults
    }

    func write(_ data: RNFWidgetData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        defaults?.set(encoded, forKey: RNFWidgetData.userDefaultsKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func write(from gameState: GameState) {
        let data = RNFWidgetData(
            streakCount: gameState.profile.streak,
            dailyCompleted: gameState.dailyCompleted,
            dailyGoal: gameState.dailyGoal,
            level: gameState.level,
            questNames: gameState.quests.map(\.name),
            questCompletions: gameState.quests.map { gameState.completedHabitIDs.contains($0.id) },
            lastUpdated: Date()
        )
        write(data)
    }
}
