import Foundation
import os

// MARK: - P25-INT-26/27/28/29/30: Habit Difficulty Profiler

/// Per-habit difficulty classification based on 30-day completion rate.
/// Provides bonus XP for hard habits and ordering preferences.
@MainActor
final class HabitDifficultyProfiler: ObservableObject {

    // MARK: - Types

    enum DifficultyTier: String, Codable, CaseIterable, Comparable {
        case easy = "easy"           // >90% completion
        case moderate = "moderate"   // 60-90% completion
        case hard = "hard"           // <60% completion

        static func < (lhs: DifficultyTier, rhs: DifficultyTier) -> Bool {
            let order: [DifficultyTier] = [.easy, .moderate, .hard]
            guard let lhsIndex = order.firstIndex(of: lhs),
                  let rhsIndex = order.firstIndex(of: rhs) else { return false }
            return lhsIndex < rhsIndex
        }
    }

    enum OrderingPreference: String, Codable {
        case hardestFirst = "hardest_first"
        case easiestFirst = "easiest_first"
        case natural      // Default/original order
    }

    struct HabitProfile: Codable, Identifiable {
        let id: UUID  // habit ID
        let habitName: String
        let completionRate: Double
        let tier: DifficultyTier
        let completedDays: Int
        let totalDays: Int
        let bonusXP: Int
        let computedAt: Date
    }

    struct HabitCompletionRecord {
        let habitId: UUID
        let habitName: String
        let date: Date
        let completed: Bool
    }

    // MARK: - Constants

    private static let analysisWindowDays = 30
    private static let easyThreshold: Double = 0.90
    private static let moderateThreshold: Double = 0.60
    private static let hardBonusXP = 3

    // MARK: - State

    @Published private(set) var profiles: [HabitProfile] = []
    @Published var orderingPreference: OrderingPreference = .natural

    // MARK: - Dependencies

    private static let logger = Logger(subsystem: "com.rnf.app", category: "habit_difficulty")

    // MARK: - Cache Keys

    private static let profilesCacheKey = "rnf_habit_difficulty_profiles"
    private static let orderingKey = "rnf_habit_ordering_preference"

    // MARK: - Init

    init() {
        loadCachedProfiles()
        loadOrderingPreference()
    }

    // MARK: - Public API

    /// Computes difficulty profiles for all habits from 30-day completion records.
    func computeProfiles(records: [HabitCompletionRecord]) -> [HabitProfile] {
        let calendar = Calendar.current
        let now = Date()

        // Filter to analysis window
        let recentRecords = records.filter {
            let daysDiff = calendar.dateComponents([.day], from: $0.date, to: now).day ?? 999
            return daysDiff < Self.analysisWindowDays
        }

        // Group by habit ID
        var habitGroups: [UUID: (name: String, records: [HabitCompletionRecord])] = [:]
        for record in recentRecords {
            var group = habitGroups[record.habitId] ?? (name: record.habitName, records: [])
            group.records.append(record)
            habitGroups[record.habitId] = group
        }

        // Compute profile for each habit
        let computed: [HabitProfile] = habitGroups.map { habitId, group in
            let totalDays = Set(group.records.map { calendar.startOfDay(for: $0.date) }).count
            let completedDays = group.records.filter { $0.completed }.count

            let rate: Double = totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0
            let tier = classifyTier(rate: rate)
            let bonus = tier == .hard ? Self.hardBonusXP : 0

            return HabitProfile(
                id: habitId,
                habitName: group.name,
                completionRate: rate,
                tier: tier,
                completedDays: completedDays,
                totalDays: totalDays,
                bonusXP: bonus,
                computedAt: Date()
            )
        }

        profiles = computed
        cacheProfiles()

        Self.logger.info("Computed \(computed.count) habit profiles: \(computed.filter { $0.tier == .hard }.count) hard, \(computed.filter { $0.tier == .moderate }.count) moderate, \(computed.filter { $0.tier == .easy }.count) easy")

        return computed
    }

    /// Returns the bonus XP for completing a specific habit.
    func bonusXP(for habitId: UUID) -> Int {
        guard let profile = profiles.first(where: { $0.id == habitId }) else { return 0 }
        return profile.bonusXP
    }

    /// Returns the difficulty tier for a specific habit.
    func tier(for habitId: UUID) -> DifficultyTier? {
        profiles.first(where: { $0.id == habitId })?.tier
    }

    /// Returns habits ordered according to the user's preference.
    func orderedHabits<T: Identifiable>(habits: [T], idMapper: (T) -> UUID) -> [T] where T.ID == UUID {
        switch orderingPreference {
        case .hardestFirst:
            return habits.sorted { a, b in
                let tierA = tier(for: idMapper(a)) ?? .moderate
                let tierB = tier(for: idMapper(b)) ?? .moderate
                return tierA > tierB
            }
        case .easiestFirst:
            return habits.sorted { a, b in
                let tierA = tier(for: idMapper(a)) ?? .moderate
                let tierB = tier(for: idMapper(b)) ?? .moderate
                return tierA < tierB
            }
        case .natural:
            return habits
        }
    }

    /// Updates the ordering preference and persists it.
    func setOrderingPreference(_ preference: OrderingPreference) {
        orderingPreference = preference
        UserDefaults.standard.set(preference.rawValue, forKey: Self.orderingKey)
        Self.logger.info("Ordering preference updated: \(preference.rawValue)")
    }

    /// Returns summary statistics for the current profiles.
    var summary: (easy: Int, moderate: Int, hard: Int) {
        let easy = profiles.filter { $0.tier == .easy }.count
        let moderate = profiles.filter { $0.tier == .moderate }.count
        let hard = profiles.filter { $0.tier == .hard }.count
        return (easy: easy, moderate: moderate, hard: hard)
    }

    /// Returns the total bonus XP available from hard habits today.
    var totalBonusXPAvailable: Int {
        profiles.filter { $0.tier == .hard }.count * Self.hardBonusXP
    }

    // MARK: - Private Helpers

    private func classifyTier(rate: Double) -> DifficultyTier {
        if rate > Self.easyThreshold {
            return .easy
        } else if rate >= Self.moderateThreshold {
            return .moderate
        } else {
            return .hard
        }
    }

    // MARK: - Caching

    private func loadCachedProfiles() {
        guard let data = UserDefaults.standard.data(forKey: Self.profilesCacheKey) else { return }
        if let cached = try? JSONDecoder().decode([HabitProfile].self, from: data) {
            profiles = cached
        }
    }

    private func cacheProfiles() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: Self.profilesCacheKey)
    }

    private func loadOrderingPreference() {
        if let raw = UserDefaults.standard.string(forKey: Self.orderingKey),
           let pref = OrderingPreference(rawValue: raw) {
            orderingPreference = pref
        }
    }

    // MARK: - Static Testable APIs

    /// Classifies a completion rate into a difficulty tier.
    static func classify(completionRate: Double) -> HabitDifficulty {
        let clamped = max(0.0, completionRate)
        if clamped > easyThreshold { return .easy }
        if clamped >= moderateThreshold { return .moderate }
        return .hard
    }

    /// Whether a habit has enough data for classification.
    static func hasEnoughData(daysSinceCreation: Int) -> Bool {
        daysSinceCreation >= 7
    }

    /// Default difficulty for new/unclassified habits.
    static let defaultDifficulty: HabitDifficulty = .moderate

    /// Whether reclassification should occur based on tier change.
    static func shouldReclassify(currentDifficulty: HabitDifficulty, newRate: Double) -> Bool {
        let newTier = classify(completionRate: newRate)
        return newTier != currentDifficulty
    }

    /// Batch classification result.
    struct ClassificationResult {
        let habitId: UUID
        let difficulty: HabitDifficulty
    }

    /// Classifies multiple habits by their completion rates.
    static func classifyBatch(_ habitRates: [(UUID, Double)]) -> [ClassificationResult] {
        habitRates.map { ClassificationResult(habitId: $0.0, difficulty: classify(completionRate: $0.1)) }
    }
}

// MARK: - HabitDifficulty Enum (Spec: P25-INT-26)

/// Top-level difficulty enum for use across the app.
/// Matches the spec's `HabitDifficulty` with XP bonus values.
enum HabitDifficulty: String, Codable, CaseIterable, Equatable {
    case easy
    case moderate
    case hard

    var bonusXP: Int {
        switch self {
        case .easy: return 0
        case .moderate: return 1
        case .hard: return 3
        }
    }
}
