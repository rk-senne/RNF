import Foundation

/// Events that can trigger a Spark Achievement on Day 1.
enum SparkEvent {
    case firstHabitCompleted
    case archetypeChosen
    case dailyGoalSet
    case firstReadingOpened
    case firstWorkoutLogged
}

/// Triggers instant achievements for new users in their first session.
/// These fire immediately on specific actions to boost Day-1 retention.
@MainActor
final class SparkAchievementTrigger {
    
    // MARK: - Spark Achievement Definitions
    
    static let sparkAchievements: [Achievement] = [
        Achievement(
            id: "spark_first_habit",
            name: "First Spark",
            description: "Complete your first-ever habit",
            category: .habits,
            requirement: 1,
            iconName: "flame.fill"
        ),
        Achievement(
            id: "spark_archetype",
            name: "Path Chosen",
            description: "Complete the archetype quiz",
            category: .level,
            requirement: 1,
            iconName: "person.crop.circle.badge.checkmark"
        ),
        Achievement(
            id: "spark_goal_set",
            name: "Intent Set",
            description: "Set your daily goal",
            category: .habits,
            requirement: 1,
            iconName: "target"
        ),
        Achievement(
            id: "spark_first_read",
            name: "Curious Mind",
            description: "Open your first reading entry",
            category: .reading,
            requirement: 1,
            iconName: "book.fill"
        ),
        Achievement(
            id: "spark_first_workout",
            name: "First Move",
            description: "Log your first workout",
            category: .workouts,
            requirement: 1,
            iconName: "figure.run"
        ),
    ]
    
    // MARK: - XP Rewards
    
    private static let xpRewards: [String: Int] = [
        "spark_first_habit": 15,
        "spark_archetype": 10,
        "spark_goal_set": 5,
        "spark_first_read": 5,
        "spark_first_workout": 10,
    ]
    
    // MARK: - Dependencies
    
    private let achievementService: AchievementService
    private let userDefaults: UserDefaults
    
    // MARK: - Keys
    
    private static let firedKey = "rnf_spark_achievements_fired"
    
    // MARK: - Init
    
    init(achievementService: AchievementService, userDefaults: UserDefaults = .standard) {
        self.achievementService = achievementService
        self.userDefaults = userDefaults
    }
    
    // MARK: - Public API
    
    /// Check and fire a spark achievement for the given event.
    /// Returns the XP reward if achievement was newly unlocked, nil otherwise.
    @discardableResult
    func fire(event: SparkEvent, userId: UUID) async -> Int? {
        let achievementId = Self.achievementID(for: event)
        
        guard !hasFired(achievementId: achievementId) else { return nil }
        
        markFired(achievementId: achievementId)
        
        try? await achievementService.unlock(userId: userId, achievementId: achievementId)
        
        return Self.xpRewards[achievementId]
    }
    
    /// XP reward for a given event (used by callers to apply XP)
    static func xpReward(for event: SparkEvent) -> Int {
        xpRewards[achievementID(for: event)] ?? 0
    }
    
    // MARK: - Mapping
    
    static func achievementID(for event: SparkEvent) -> String {
        switch event {
        case .firstHabitCompleted: return "spark_first_habit"
        case .archetypeChosen: return "spark_archetype"
        case .dailyGoalSet: return "spark_goal_set"
        case .firstReadingOpened: return "spark_first_read"
        case .firstWorkoutLogged: return "spark_first_workout"
        }
    }
    
    // MARK: - Deduplication
    
    private func hasFired(achievementId: String) -> Bool {
        let fired = userDefaults.stringArray(forKey: Self.firedKey) ?? []
        return fired.contains(achievementId)
    }
    
    private func markFired(achievementId: String) {
        var fired = userDefaults.stringArray(forKey: Self.firedKey) ?? []
        fired.append(achievementId)
        userDefaults.set(fired, forKey: Self.firedKey)
    }
}
