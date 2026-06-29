import Foundation

// P20-EXP-12b: Seasonal Arc progress system — UserDefaults backed
struct SeasonalArcService {
    private static let progressKey = "rnf_arc_progress"
    private static let completedKey = "rnf_arc_completed"

    /// Progress is 0.0 to 1.0. Incremented by matching actions during the month.
    static func progress() -> Double {
        let key = currentProgressKey()
        return UserDefaults.standard.double(forKey: key)
    }

    static func addProgress(_ amount: Double) {
        let key = currentProgressKey()
        let current = UserDefaults.standard.double(forKey: key)
        let new = min(current + amount, 1.0)
        UserDefaults.standard.set(new, forKey: key)
    }

    static func isCompleted() -> Bool {
        let key = currentCompletedKey()
        return UserDefaults.standard.bool(forKey: key)
    }

    static func markCompleted() {
        let key = currentCompletedKey()
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Returns all arc IDs that were completed (for archive display)
    static func completedArcs() -> [String] {
        UserDefaults.standard.stringArray(forKey: completedKey) ?? []
    }

    static func recordCompletion(arcName: String, month: Int, year: Int) {
        var completed = completedArcs()
        let id = "\(arcName)_\(year)_\(month)"
        guard !completed.contains(id) else { return }
        completed.append(id)
        UserDefaults.standard.set(completed, forKey: completedKey)
    }

    /// How much progress a single action contributes (assume ~60 actions to complete)
    static let actionIncrement: Double = 1.0 / 60.0

    private static func currentProgressKey() -> String {
        let c = Calendar.current
        let month = c.component(.month, from: Date())
        let year = c.component(.year, from: Date())
        return "\(progressKey)_\(year)_\(month)"
    }

    private static func currentCompletedKey() -> String {
        let c = Calendar.current
        let month = c.component(.month, from: Date())
        let year = c.component(.year, from: Date())
        return "rnf_arc_done_\(year)_\(month)"
    }
}
