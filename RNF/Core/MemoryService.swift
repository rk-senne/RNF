import Foundation

// P20-EXP-09a: Persistence layer for milestone memory snapshots
struct MemoryService {
    private static let key = "rnf_progress_snapshots"

    static func save(_ snapshot: ProgressSnapshot) {
        var all = loadAll()
        guard !all.contains(where: { $0.id == snapshot.id }) else { return }
        all.append(snapshot)
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func loadAll() -> [ProgressSnapshot] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let snapshots = try? JSONDecoder().decode([ProgressSnapshot].self, from: data)
        else { return [] }
        return snapshots
    }

    static func snapshot(for milestone: String) -> ProgressSnapshot? {
        loadAll().first { $0.milestone == milestone }
    }
}
