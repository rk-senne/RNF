import Foundation
import Combine

@MainActor
final class SyncFlushService {

    private let dailyLogService: DailyLogService
    private let networkMonitor: NetworkMonitor
    private let offlineQueue: OfflineWriteQueue
    private var cancellable: AnyCancellable?

    init(dailyLogService: DailyLogService = DailyLogService(), networkMonitor: NetworkMonitor = .shared, offlineQueue: OfflineWriteQueue = .shared) {
        self.dailyLogService = dailyLogService
        self.networkMonitor = networkMonitor
        self.offlineQueue = offlineQueue

        cancellable = networkMonitor.$isConnected
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in Task { await self?.flush() } }
    }

    func flush() async {
        let items = offlineQueue.dequeueAll()
        for item in items {
            let completion = HabitCompletion(
                id: item.id, user_id: item.userId, habit_id: item.habitId,
                completed_at: item.completedAt, date: item.date, xp_awarded: item.xpAwarded
            )
            _ = try? await dailyLogService.recordHabitCompletion(completion)
        }
    }
}
