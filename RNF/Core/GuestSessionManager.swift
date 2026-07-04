import Foundation

// P22-ONB-01: Anonymous local state with 3-day TTL for guest tryout experience.
@MainActor
final class GuestSessionManager: ObservableObject {

    // MARK: - Published State

    @Published var guestXP: Int = 0
    @Published var completedHabitIDs: Set<String> = []
    @Published var isSessionActive: Bool = false
    @Published var isSessionExpired: Bool = false

    // MARK: - Constants

    private static let ttlDays: TimeInterval = 3 * 24 * 60 * 60
    private static let xpKey = "rnf_guest_xp"
    private static let habitsKey = "rnf_guest_completed_habits"
    private static let expiryKey = "rnf_guest_session_expiry"
    private static let activeKey = "rnf_guest_session_active"

    // MARK: - Dependencies

    private let defaults: UserDefaults

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadSession()
    }

    // MARK: - Session Lifecycle

    func startSession() {
        let expiry = Date().addingTimeInterval(Self.ttlDays)
        defaults.set(expiry.timeIntervalSince1970, forKey: Self.expiryKey)
        defaults.set(true, forKey: Self.activeKey)
        isSessionActive = true
        isSessionExpired = false
        guestXP = 0
        completedHabitIDs = []
        persist()
    }

    func endSession() {
        defaults.removeObject(forKey: Self.xpKey)
        defaults.removeObject(forKey: Self.habitsKey)
        defaults.removeObject(forKey: Self.expiryKey)
        defaults.removeObject(forKey: Self.activeKey)
        isSessionActive = false
        isSessionExpired = false
        guestXP = 0
        completedHabitIDs = []
    }

    // MARK: - Habit Completion

    func completeHabit(id: String, xpReward: Int) {
        guard isSessionActive, !isSessionExpired else { return }
        guard !completedHabitIDs.contains(id) else { return }

        completedHabitIDs.insert(id)
        guestXP += xpReward
        persist()
    }

    // MARK: - Data Access (for migration)

    var sessionData: GuestSessionData? {
        guard isSessionActive else { return nil }
        return GuestSessionData(
            xp: guestXP,
            completedHabitIDs: completedHabitIDs
        )
    }

    // MARK: - Private

    private func loadSession() {
        let isActive = defaults.bool(forKey: Self.activeKey)
        guard isActive else {
            isSessionActive = false
            return
        }

        let expiryTimestamp = defaults.double(forKey: Self.expiryKey)
        let expiryDate = Date(timeIntervalSince1970: expiryTimestamp)

        if Date() > expiryDate {
            isSessionExpired = true
            isSessionActive = true
            return
        }

        isSessionActive = true
        isSessionExpired = false
        guestXP = defaults.integer(forKey: Self.xpKey)

        if let habitsData = defaults.data(forKey: Self.habitsKey),
           let habits = try? JSONDecoder().decode(Set<String>.self, from: habitsData) {
            completedHabitIDs = habits
        }
    }

    private func persist() {
        defaults.set(guestXP, forKey: Self.xpKey)
        if let habitsData = try? JSONEncoder().encode(completedHabitIDs) {
            defaults.set(habitsData, forKey: Self.habitsKey)
        }
    }
}

// MARK: - Supporting Types

struct GuestSessionData {
    let xp: Int
    let completedHabitIDs: Set<String>
}
