import Foundation

// P27-LIF-33/34/35/36/37: Legacy Profile Generator
// Aggregates full journey stats for Day 365+ achievements.
// Custom titles, time capsule scheduling, journey summaries.

@MainActor
final class LegacyProfileGenerator: ObservableObject {

    // MARK: - Types

    struct LegacyProfile: Codable {
        let generatedAt: Date
        let totalDaysActive: Int
        let totalHabitsCompleted: Int
        let totalWorkouts: Int
        let totalPagesRead: Int
        let longestStreak: Int
        let rebirthCount: Int
        let chaptersCompleted: Int
        let titlesEarned: [String]
        let achievementsUnlocked: Int
        let highestLevel: Int
        let peakStats: Stats
        let seasonalEventsCompleted: Int
        let customTitle: String?
    }

    struct TimeCapsule: Codable, Identifiable {
        let id: UUID
        let createdAt: Date
        let revealAt: Date
        let message: String
        let statsSnapshot: Stats
        let levelSnapshot: Int
        var isRevealed: Bool

        init(message: String, revealAfterDays: Int, stats: Stats, level: Int) {
            self.id = UUID()
            self.createdAt = Date()
            self.revealAt = Calendar.current.date(byAdding: .day, value: revealAfterDays, to: Date()) ?? Date()
            self.message = message
            self.statsSnapshot = stats
            self.levelSnapshot = level
            self.isRevealed = false
        }
    }

    struct LegacyMilestone: Codable, Identifiable {
        let id: String
        let name: String
        let description: String
        let dayRequirement: Int
        let title: String
        var unlockedAt: Date?

        var isUnlocked: Bool { unlockedAt != nil }
    }

    // MARK: - Published State

    @Published private(set) var legacyProfile: LegacyProfile?
    @Published private(set) var timeCapsules: [TimeCapsule] = []
    @Published private(set) var milestones: [LegacyMilestone] = []
    @Published private(set) var customTitle: String?

    // MARK: - Dependencies

    private let supabase: SupabaseService
    private let userDefaults: UserDefaults

    // MARK: - UserDefaults Keys

    private static let profileKey = "rnf_legacy_profile"
    private static let capsulesKey = "rnf_time_capsules"
    private static let customTitleKey = "rnf_legacy_custom_title"
    private static let milestonesKey = "rnf_legacy_milestones"

    // MARK: - Static Data

    static let allMilestones: [LegacyMilestone] = [
        LegacyMilestone(id: "year_one", name: "Year One", description: "365 days in the forge", dayRequirement: 365, title: "Year Forged"),
        LegacyMilestone(id: "year_two", name: "Year Two", description: "730 days of dedication", dayRequirement: 730, title: "Eternal Flame"),
        LegacyMilestone(id: "half_year", name: "Half Year", description: "180 days of consistency", dayRequirement: 180, title: "Half Forged"),
        LegacyMilestone(id: "thousand_days", name: "Thousand Days", description: "1000 days committed", dayRequirement: 1000, title: "Legendary"),
    ]

    // MARK: - Init

    init(supabase: SupabaseService = .shared, userDefaults: UserDefaults = .standard) {
        self.supabase = supabase
        self.userDefaults = userDefaults
        loadLocal()
    }

    // MARK: - Public API

    /// Generate a full legacy profile from aggregated journey data
    func generateProfile(
        totalDaysActive: Int,
        totalHabitsCompleted: Int,
        totalWorkouts: Int,
        totalPagesRead: Int,
        longestStreak: Int,
        rebirthCount: Int,
        chaptersCompleted: Int,
        titlesEarned: [String],
        achievementsUnlocked: Int,
        highestLevel: Int,
        peakStats: Stats,
        seasonalEventsCompleted: Int
    ) -> LegacyProfile {
        let profile = LegacyProfile(
            generatedAt: Date(),
            totalDaysActive: totalDaysActive,
            totalHabitsCompleted: totalHabitsCompleted,
            totalWorkouts: totalWorkouts,
            totalPagesRead: totalPagesRead,
            longestStreak: longestStreak,
            rebirthCount: rebirthCount,
            chaptersCompleted: chaptersCompleted,
            titlesEarned: titlesEarned,
            achievementsUnlocked: achievementsUnlocked,
            highestLevel: highestLevel,
            peakStats: peakStats,
            seasonalEventsCompleted: seasonalEventsCompleted,
            customTitle: customTitle
        )

        legacyProfile = profile
        saveLocal()
        syncProfileToRemote(profile)
        return profile
    }

    /// Set a custom title for the legacy profile
    func setCustomTitle(_ title: String) {
        guard title.count <= 30, !title.isEmpty else { return }
        customTitle = title
        userDefaults.set(title, forKey: Self.customTitleKey)
    }

    /// Schedule a time capsule to be revealed in the future
    func scheduleTimeCapsule(message: String, revealAfterDays: Int, currentStats: Stats, currentLevel: Int) {
        guard message.count <= 500, revealAfterDays > 0 else { return }

        let capsule = TimeCapsule(
            message: message,
            revealAfterDays: revealAfterDays,
            stats: currentStats,
            level: currentLevel
        )

        timeCapsules.append(capsule)
        saveLocal()
        syncCapsuleToRemote(capsule)
    }

    /// Check for capsules ready to be revealed
    func checkRevealableCapsules() -> [TimeCapsule] {
        let now = Date()
        var revealed: [TimeCapsule] = []

        for i in timeCapsules.indices {
            if !timeCapsules[i].isRevealed && timeCapsules[i].revealAt <= now {
                timeCapsules[i].isRevealed = true
                revealed.append(timeCapsules[i])
            }
        }

        if !revealed.isEmpty {
            saveLocal()
        }

        return revealed
    }

    /// Check and unlock day-based milestones
    func evaluateMilestones(totalDaysActive: Int) -> [LegacyMilestone] {
        if milestones.isEmpty {
            milestones = Self.allMilestones
        }

        var newlyUnlocked: [LegacyMilestone] = []

        for i in milestones.indices {
            if milestones[i].unlockedAt == nil && totalDaysActive >= milestones[i].dayRequirement {
                milestones[i].unlockedAt = Date()
                newlyUnlocked.append(milestones[i])
            }
        }

        if !newlyUnlocked.isEmpty {
            saveLocal()
            syncMilestonesToRemote(newlyUnlocked)
        }

        return newlyUnlocked
    }

    /// Sync from remote on app launch
    func syncFromRemote(userID: UUID) async {
        guard let client = supabase.client else { return }

        do {
            struct MilestoneRow: Decodable {
                let milestone_id: String
                let unlocked_at: String?
            }

            let rows: [MilestoneRow] = try await client
                .from("legacy_milestones")
                .select()
                .eq("user_id", value: userID.uuidString)
                .execute()
                .value

            let formatter = ISO8601DateFormatter()
            for row in rows {
                if let idx = milestones.firstIndex(where: { $0.id == row.milestone_id }),
                   milestones[idx].unlockedAt == nil,
                   let dateStr = row.unlocked_at {
                    milestones[idx].unlockedAt = formatter.date(from: dateStr)
                }
            }

            saveLocal()
        } catch {
            RNFLogger.challenge.error("LegacyProfileGenerator: syncFromRemote failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Local Persistence

    private func loadLocal() {
        if let data = userDefaults.data(forKey: Self.profileKey),
           let profile = try? JSONDecoder().decode(LegacyProfile.self, from: data) {
            legacyProfile = profile
        }

        if let data = userDefaults.data(forKey: Self.capsulesKey),
           let capsules = try? JSONDecoder().decode([TimeCapsule].self, from: data) {
            timeCapsules = capsules
        }

        if let data = userDefaults.data(forKey: Self.milestonesKey),
           let decoded = try? JSONDecoder().decode([LegacyMilestone].self, from: data) {
            milestones = decoded
        } else {
            milestones = Self.allMilestones
        }

        customTitle = userDefaults.string(forKey: Self.customTitleKey)
    }

    private func saveLocal() {
        if let profile = legacyProfile,
           let data = try? JSONEncoder().encode(profile) {
            userDefaults.set(data, forKey: Self.profileKey)
        }

        if let data = try? JSONEncoder().encode(timeCapsules) {
            userDefaults.set(data, forKey: Self.capsulesKey)
        }

        if let data = try? JSONEncoder().encode(milestones) {
            userDefaults.set(data, forKey: Self.milestonesKey)
        }
    }

    // MARK: - Remote Sync

    private func syncProfileToRemote(_ profile: LegacyProfile) {
        guard let client = supabase.client else { return }

        Task {
            do {
                struct ProfileUpsert: Encodable {
                    let total_days_active: Int
                    let total_habits_completed: Int
                    let highest_level: Int
                    let longest_streak: Int
                    let rebirth_count: Int
                    let custom_title: String?
                    let updated_at: String
                }

                let formatter = ISO8601DateFormatter()
                let upsert = ProfileUpsert(
                    total_days_active: profile.totalDaysActive,
                    total_habits_completed: profile.totalHabitsCompleted,
                    highest_level: profile.highestLevel,
                    longest_streak: profile.longestStreak,
                    rebirth_count: profile.rebirthCount,
                    custom_title: profile.customTitle,
                    updated_at: formatter.string(from: Date())
                )

                try await client
                    .from("legacy_milestones")
                    .upsert(upsert)
                    .execute()
            } catch {
                RNFLogger.challenge.error("LegacyProfileGenerator: syncProfile failed — \(error.localizedDescription)")
            }
        }
    }

    private func syncCapsuleToRemote(_ capsule: TimeCapsule) {
        guard let client = supabase.client else { return }

        Task {
            do {
                struct CapsuleInsert: Encodable {
                    let message: String
                    let reveal_at: String
                    let created_at: String
                }

                let formatter = ISO8601DateFormatter()
                let insert = CapsuleInsert(
                    message: capsule.message,
                    reveal_at: formatter.string(from: capsule.revealAt),
                    created_at: formatter.string(from: capsule.createdAt)
                )

                try await client
                    .from("time_capsules")
                    .insert(insert)
                    .execute()
            } catch {
                RNFLogger.challenge.error("LegacyProfileGenerator: syncCapsule failed — \(error.localizedDescription)")
            }
        }
    }

    private func syncMilestonesToRemote(_ milestones: [LegacyMilestone]) {
        guard let client = supabase.client else { return }

        Task {
            do {
                let formatter = ISO8601DateFormatter()

                struct MilestoneUpsert: Encodable {
                    let milestone_id: String
                    let unlocked_at: String
                }

                for milestone in milestones {
                    guard let unlockedAt = milestone.unlockedAt else { continue }

                    let upsert = MilestoneUpsert(
                        milestone_id: milestone.id,
                        unlocked_at: formatter.string(from: unlockedAt)
                    )

                    try await client
                        .from("legacy_milestones")
                        .upsert(upsert)
                        .execute()
                }
            } catch {
                RNFLogger.challenge.error("LegacyProfileGenerator: syncMilestones failed — \(error.localizedDescription)")
            }
        }
    }
}
