import Foundation
import Combine

/// Flushes offline queue when connectivity restores.
/// Includes exponential backoff on retry (P21-DATA-02).
@MainActor
final class SyncFlushService {

    private let dailyLogService: DailyLogService
    private let networkMonitor: NetworkMonitor
    private let offlineQueue: OfflineWriteQueue
    private var cancellable: AnyCancellable?

    private static let maxRetries = 5
    private static let baseDelay: UInt64 = 1_000_000_000 // 1 second

    init(
        dailyLogService: DailyLogService = DailyLogService(),
        networkMonitor: NetworkMonitor = .shared,
        offlineQueue: OfflineWriteQueue = .shared
    ) {
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
        var failedWrites: [OfflineWriteQueue.PendingWrite] = []

        for item in items {
            let success = await processWrite(item)
            if !success && item.retryCount < Self.maxRetries {
                failedWrites.append(item)
            }
        }

        // Requeue failed items for next flush
        if !failedWrites.isEmpty {
            offlineQueue.requeueFailed(failedWrites)
        }
    }

    private func processWrite(_ write: OfflineWriteQueue.PendingWrite) async -> Bool {
        // Exponential backoff: 1s, 2s, 4s, 8s, 16s
        if write.retryCount > 0 {
            let delay = Self.baseDelay * UInt64(1 << min(write.retryCount, 4))
            try? await Task.sleep(nanoseconds: delay)
        }

        switch write.type {
        case .habitCompletion:
            return await flushHabitCompletion(write)
        case .workoutCompletion:
            return await flushWorkoutCompletion(write)
        case .readingCompletion:
            return await flushReadingCompletion(write)
        }
    }

    private func flushHabitCompletion(_ write: OfflineWriteQueue.PendingWrite) async -> Bool {
        guard let completion = try? JSONDecoder().decode(
            OfflineWriteQueue.PendingCompletion.self, from: write.payload
        ) else { return true } // Malformed data, don't retry

        let habitCompletion = HabitCompletion(
            id: completion.id,
            user_id: completion.userId,
            habit_id: completion.habitId,
            completed_at: completion.completedAt,
            date: completion.date,
            xp_awarded: completion.xpAwarded
        )

        do {
            _ = try await dailyLogService.recordHabitCompletion(habitCompletion)
            return true
        } catch {
            return false
        }
    }

    private func flushWorkoutCompletion(_ write: OfflineWriteQueue.PendingWrite) async -> Bool {
        guard let completion = try? JSONDecoder().decode(
            PendingWorkoutCompletion.self, from: write.payload
        ) else { return true } // Malformed data, don't retry

        do {
            let workoutService = WorkoutService()
            _ = try await workoutService.completeWorkout(userId: write.userId, date: completion.date)
            return true
        } catch {
            return false
        }
    }

    private func flushReadingCompletion(_ write: OfflineWriteQueue.PendingWrite) async -> Bool {
        guard let completion = try? JSONDecoder().decode(
            PendingReadingCompletion.self, from: write.payload
        ) else { return true } // Malformed data, don't retry

        do {
            let readingService = ReadingService()
            _ = try await readingService.completeReading(userId: write.userId, date: completion.date)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Payload Models

    private struct PendingWorkoutCompletion: Codable {
        let date: Date
    }

    private struct PendingReadingCompletion: Codable {
        let date: Date
    }
}
