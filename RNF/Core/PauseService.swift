import Foundation

// MARK: - P22-EMO-09: PauseService

/// Manages intentional pause periods — 1 per cycle, max 14 days.
/// During a pause, streak penalties are suspended.
@MainActor
struct PauseService {

    private static let storageKey = "rnf_pause_periods"

    // MARK: - Models

    struct PausePeriod: Codable, Identifiable {
        let id: UUID
        let startDate: Date
        let endDate: Date
        let cycleID: String

        var isActive: Bool {
            let now = Date()
            return now >= startDate && now <= endDate
        }

        var durationDays: Int {
            Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        }
    }

    // MARK: - Activate

    /// Activates a pause for the given cycle. Returns nil if already used this cycle or duration exceeds 14 days.
    @discardableResult
    static func activate(days: Int, cycleID: String) -> PausePeriod? {
        guard days >= 1, days <= 14 else {
            RNFLogger.log("PauseService: Invalid duration \(days). Must be 1-14.")
            return nil
        }

        let existing = loadPeriods()

        // Enforce 1 pause per cycle
        if existing.contains(where: { $0.cycleID == cycleID }) {
            RNFLogger.log("PauseService: Pause already used for cycle \(cycleID).")
            return nil
        }

        let start = Date()
        guard let end = Calendar.current.date(byAdding: .day, value: days, to: start) else {
            return nil
        }

        let period = PausePeriod(id: UUID(), startDate: start, endDate: end, cycleID: cycleID)

        var periods = existing
        periods.append(period)
        savePeriods(periods)

        RNFLogger.log("PauseService: Activated \(days)-day pause for cycle \(cycleID).")
        return period
    }

    /// Activates a retroactive pause (e.g. "Life Happened" flow).
    /// Backdates the start to cover missed days.
    @discardableResult
    static func activateRetroactive(missedDays: Int, cycleID: String) -> PausePeriod? {
        let clampedDays = min(missedDays, 14)
        guard clampedDays >= 1 else { return nil }

        let existing = loadPeriods()

        if existing.contains(where: { $0.cycleID == cycleID }) {
            RNFLogger.log("PauseService: Retroactive pause denied - already used for cycle \(cycleID).")
            return nil
        }

        let end = Date()
        guard let start = Calendar.current.date(byAdding: .day, value: -clampedDays, to: end) else {
            return nil
        }

        let period = PausePeriod(id: UUID(), startDate: start, endDate: end, cycleID: cycleID)

        var periods = existing
        periods.append(period)
        savePeriods(periods)

        RNFLogger.log("PauseService: Retroactive pause of \(clampedDays) days for cycle \(cycleID).")
        return period
    }

    // MARK: - Validate

    /// Returns true if a pause is currently active for any cycle.
    static func isCurrentlyPaused() -> Bool {
        loadPeriods().contains(where: { $0.isActive })
    }

    /// Returns true if a date falls within any pause period.
    static func isPaused(on date: Date) -> Bool {
        loadPeriods().contains { period in
            date >= period.startDate && date <= period.endDate
        }
    }

    /// Returns true if the given cycle has already used its pause allowance.
    static func hasUsedPause(forCycle cycleID: String) -> Bool {
        loadPeriods().contains(where: { $0.cycleID == cycleID })
    }

    // MARK: - Query

    /// Returns all pause periods, ordered by start date descending.
    static func allPeriods() -> [PausePeriod] {
        loadPeriods().sorted { $0.startDate > $1.startDate }
    }

    /// Returns the active pause period, if any.
    static func activePause() -> PausePeriod? {
        loadPeriods().first(where: { $0.isActive })
    }

    /// Returns total paused days across all cycles.
    static func totalPausedDays() -> Int {
        loadPeriods().reduce(0) { $0 + $1.durationDays }
    }

    // MARK: - Persistence

    private static func loadPeriods() -> [PausePeriod] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let periods = try? JSONDecoder().decode([PausePeriod].self, from: data)
        else { return [] }
        return periods
    }

    private static func savePeriods(_ periods: [PausePeriod]) {
        if let data = try? JSONEncoder().encode(periods) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
