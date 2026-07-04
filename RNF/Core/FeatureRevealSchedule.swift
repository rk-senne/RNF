import Foundation

// P22-ONB-12: Maps features to unlock days for progressive disclosure.
@MainActor
final class FeatureRevealSchedule: ObservableObject {

    // MARK: - Published State

    @Published var unlockedFeatures: Set<Feature> = []

    // MARK: - Feature Registry

    enum Feature: String, CaseIterable, Hashable {
        case habits          // Day 0 (immediate)
        case xpSystem        // Day 0 (immediate)
        case stats           // Day 1
        case streak          // Day 2
        case quests          // Day 3
        case boss            // Day 5
        case challenges      // Day 7
        case mastery         // Day 10
        case guild           // Day 14
        case journey         // Day 21
        case leaderboard     // Day 7
        case customHabits    // Day 4
        case focusTimer      // Day 3
        case reading         // Day 5
        case achievements    // Day 7
        case weeklyReport    // Day 7

        var unlockDay: Int {
            switch self {
            case .habits:       return 0
            case .xpSystem:     return 0
            case .stats:        return 1
            case .streak:       return 2
            case .quests:       return 3
            case .focusTimer:   return 3
            case .customHabits: return 4
            case .boss:         return 5
            case .reading:      return 5
            case .challenges:   return 7
            case .leaderboard:  return 7
            case .achievements: return 7
            case .weeklyReport: return 7
            case .mastery:      return 10
            case .guild:        return 14
            case .journey:      return 21
            }
        }

        var displayName: String {
            switch self {
            case .habits:       return "Daily Habits"
            case .xpSystem:     return "XP System"
            case .stats:        return "Stat Tracking"
            case .streak:       return "Streaks"
            case .quests:       return "Quests"
            case .boss:         return "Boss Battles"
            case .challenges:   return "Challenges"
            case .mastery:      return "Mastery Paths"
            case .guild:        return "Guilds"
            case .journey:      return "Journey Map"
            case .leaderboard:  return "Leaderboard"
            case .customHabits: return "Custom Habits"
            case .focusTimer:   return "Focus Timer"
            case .reading:      return "Reading Tracker"
            case .achievements: return "Achievements"
            case .weeklyReport: return "Weekly Report"
            }
        }

        var teaseDescription: String {
            switch self {
            case .habits:       return "Build daily habits to earn XP"
            case .xpSystem:     return "Gain experience for every action"
            case .stats:        return "Track Body, Mind & Spirit growth"
            case .streak:       return "Keep your fire burning daily"
            case .quests:       return "Multi-day missions for bonus XP"
            case .boss:         return "Battle weekly bosses with your habits"
            case .challenges:   return "Compete with friends"
            case .mastery:      return "Specialize in your chosen path"
            case .guild:        return "Join a team for shared goals"
            case .journey:      return "See your full transformation story"
            case .leaderboard:  return "Climb the ranks"
            case .customHabits: return "Create habits unique to you"
            case .focusTimer:   return "Deep work sessions for bonus XP"
            case .reading:      return "Track pages and earn wisdom XP"
            case .achievements: return "Collect badges for milestones"
            case .weeklyReport: return "Review your weekly progress"
            }
        }
    }

    // MARK: - Dependencies

    private let defaults: UserDefaults
    private static let startDateKey = "rnf_player_start_date"

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        refreshUnlockedFeatures()
    }

    // MARK: - Public API

    func isUnlocked(_ feature: Feature) -> Bool {
        unlockedFeatures.contains(feature)
    }

    func daysUntilUnlock(_ feature: Feature) -> Int {
        let elapsed = daysSinceStart()
        return max(feature.unlockDay - elapsed, 0)
    }

    func nextUnlocks() -> [Feature] {
        let elapsed = daysSinceStart()
        return Feature.allCases
            .filter { $0.unlockDay > elapsed }
            .sorted { $0.unlockDay < $1.unlockDay }
    }

    func refreshUnlockedFeatures() {
        let elapsed = daysSinceStart()
        unlockedFeatures = Set(Feature.allCases.filter { $0.unlockDay <= elapsed })
    }

    func recordStartDate() {
        guard defaults.object(forKey: Self.startDateKey) == nil else { return }
        defaults.set(Date().timeIntervalSince1970, forKey: Self.startDateKey)
        refreshUnlockedFeatures()
    }

    // MARK: - Private

    private func daysSinceStart() -> Int {
        guard let timestamp = defaults.object(forKey: Self.startDateKey) as? TimeInterval else {
            return 0
        }
        let start = Date(timeIntervalSince1970: timestamp)
        let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return max(days, 0)
    }
}
