import SwiftUI

@main
struct RNFWatchApp: App {
    @StateObject private var watchState = WatchAppState()

    var body: some Scene {
        WindowGroup {
            WatchHabitListView(state: watchState)
        }
    }
}

@MainActor
final class WatchAppState: ObservableObject {
    @Published var snapshot: WatchDailySnapshot = WatchDailySnapshot(
        date: Date(), level: 1, streak: 0,
        dailyCompleted: 0, dailyGoal: 4, challengeDay: nil, habits: []
    )

    func update(from data: Data) {
        guard let decoded = try? JSONDecoder().decode(WatchDailySnapshot.self, from: data) else { return }
        snapshot = decoded
    }
}
