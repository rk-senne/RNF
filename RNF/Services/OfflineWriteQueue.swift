import Foundation

final class OfflineWriteQueue {

    static let shared = OfflineWriteQueue()

    private static let storageKey = "rnf_offline_queue"

    struct PendingCompletion: Codable {
        let id: UUID
        let userId: UUID
        let habitId: UUID
        let date: Date
        let xpAwarded: Int
        let completedAt: Date
    }

    private(set) var pending: [PendingCompletion] = []

    init() {
        load()
    }

    func enqueue(_ completion: PendingCompletion) {
        pending.append(completion)
        save()
    }

    func dequeueAll() -> [PendingCompletion] {
        let items = pending
        pending.removeAll()
        save()
        return items
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(pending) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let items = try? JSONDecoder().decode([PendingCompletion].self, from: data)
        else { return }
        pending = items
    }
}
