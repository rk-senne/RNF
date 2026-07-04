import Foundation

/// Generic offline write queue supporting habit completions, workouts, and reading.
/// Includes max size (500 items) and 30-day TTL eviction (P21-DATA-01/02/03).
@MainActor
final class OfflineWriteQueue {

    static let shared = OfflineWriteQueue()

    private static let storageKey = "rnf_offline_queue"
    private static let maxQueueSize = 500
    private static let ttlDays = 30

    // MARK: - Generic PendingWrite

    enum WriteType: String, Codable {
        case habitCompletion
        case workoutCompletion
        case readingCompletion
    }

    struct PendingWrite: Codable, Identifiable {
        let id: UUID
        let type: WriteType
        let userId: UUID
        let payload: Data
        let createdAt: Date
        var retryCount: Int

        init(id: UUID = UUID(), type: WriteType, userId: UUID, payload: Data, retryCount: Int = 0) {
            self.id = id
            self.type = type
            self.userId = userId
            self.payload = payload
            self.createdAt = Date()
            self.retryCount = retryCount
        }
    }

    // Legacy support
    struct PendingCompletion: Codable {
        let id: UUID
        let userId: UUID
        let habitId: UUID
        let date: Date
        let xpAwarded: Int
        let completedAt: Date
    }

    private(set) var pending: [PendingWrite] = []

    init() {
        load()
        evictExpired()
    }

    // MARK: - Public API

    func enqueue(_ write: PendingWrite) {
        // Enforce max size
        if pending.count >= Self.maxQueueSize {
            pending.removeFirst()
        }
        pending.append(write)
        save()
    }

    /// Convenience for habit completions (legacy API).
    func enqueue(_ completion: PendingCompletion) {
        guard let payload = try? JSONEncoder().encode(completion) else { return }
        let write = PendingWrite(
            id: completion.id,
            type: .habitCompletion,
            userId: completion.userId,
            payload: payload
        )
        enqueue(write)
    }

    func dequeueAll() -> [PendingWrite] {
        let items = pending
        pending.removeAll()
        save()
        return items
    }

    func requeueFailed(_ writes: [PendingWrite]) {
        for var write in writes {
            write.retryCount += 1
            pending.append(write)
        }
        save()
    }

    var count: Int { pending.count }
    var isEmpty: Bool { pending.isEmpty }

    // MARK: - TTL Eviction

    private func evictExpired() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -Self.ttlDays, to: Date()) ?? Date()
        let before = pending.count
        pending.removeAll { $0.createdAt < cutoff }
        if pending.count != before {
            save()
        }
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(pending) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let items = try? JSONDecoder().decode([PendingWrite].self, from: data)
        else { return }
        pending = items
    }
}
