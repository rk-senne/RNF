import Foundation

// P27-LIF-07/08/09/10/11/12/13: Rebirth/Prestige system
// Allows players to reset progress for permanent bonuses.
// Preserves titles, achievements, and forge tokens across rebirths.

@MainActor
final class PrestigeService: ObservableObject {

    // MARK: - Types

    struct RebirthRecord: Codable, Identifiable {
        let id: UUID
        let rebirthNumber: Int
        let performedAt: Date
        let levelAtRebirth: Int
        let statsAtRebirth: Stats
        let titlesPreserved: [String]
        let achievementsPreserved: [String]

        init(
            rebirthNumber: Int,
            performedAt: Date = Date(),
            levelAtRebirth: Int,
            statsAtRebirth: Stats,
            titlesPreserved: [String],
            achievementsPreserved: [String]
        ) {
            self.id = UUID()
            self.rebirthNumber = rebirthNumber
            self.performedAt = performedAt
            self.levelAtRebirth = levelAtRebirth
            self.statsAtRebirth = statsAtRebirth
            self.titlesPreserved = titlesPreserved
            self.achievementsPreserved = achievementsPreserved
        }
    }

    struct RebirthPreview {
        let xpBonusPercent: Int
        let startingStatBonus: Int
        let preservedTitles: [String]
        let preservedAchievements: [String]
        let preservedTokens: Int
        let resetsLevel: Bool
        let resetsStats: Bool
        let resetsXP: Bool
    }

    enum RebirthEligibility {
        case eligible
        case needsChapterTwo
        case needsLevelTwenty
        case needsChallenge
    }

    // MARK: - Published State

    @Published private(set) var rebirthCount: Int = 0
    @Published private(set) var records: [RebirthRecord] = []
    @Published private(set) var xpBonusMultiplier: Double = 1.0
    @Published private(set) var startingStatBonus: Int = 0

    // MARK: - Dependencies

    private let supabase: SupabaseService
    private let userDefaults: UserDefaults

    // MARK: - UserDefaults Keys

    private static let rebirthCountKey = "rnf_prestige_rebirth_count"
    private static let recordsKey = "rnf_prestige_records"

    // MARK: - Constants

    static let xpBonusPerRebirth: Double = 0.05
    static let statBonusMinRebirth: Int = 2

    // MARK: - Init

    init(supabase: SupabaseService = .shared, userDefaults: UserDefaults = .standard) {
        self.supabase = supabase
        self.userDefaults = userDefaults
        loadLocal()
        recalculateBonuses()
    }

    // MARK: - Public API

    /// Check if the player can rebirth: Chapter 2 complete OR (Level 20 + challenge done)
    func checkEligibility(
        chapterTwoComplete: Bool,
        currentLevel: Int,
        challengeCompleted: Bool
    ) -> RebirthEligibility {
        if chapterTwoComplete {
            return .eligible
        }

        if currentLevel >= 20 && challengeCompleted {
            return .eligible
        }

        if currentLevel < 20 {
            return .needsLevelTwenty
        }

        if !challengeCompleted {
            return .needsChallenge
        }

        return .needsChapterTwo
    }

    /// Generate a preview of what the rebirth will do
    func generatePreview(
        currentTitles: [String],
        currentAchievements: [String],
        currentTokenBalance: Int
    ) -> RebirthPreview {
        let nextRebirthNumber = rebirthCount + 1
        let bonusPercent = Int(Double(nextRebirthNumber) * Self.xpBonusPerRebirth * 100)
        let statBonus = nextRebirthNumber >= Self.statBonusMinRebirth ? nextRebirthNumber - 1 : 0

        return RebirthPreview(
            xpBonusPercent: bonusPercent,
            startingStatBonus: statBonus,
            preservedTitles: currentTitles,
            preservedAchievements: currentAchievements,
            preservedTokens: currentTokenBalance,
            resetsLevel: true,
            resetsStats: true,
            resetsXP: true
        )
    }

    /// Execute the rebirth. Returns the new starting stats with bonuses applied.
    func performRebirth(
        currentLevel: Int,
        currentStats: Stats,
        currentTitles: [String],
        currentAchievements: [String]
    ) -> Stats {
        let record = RebirthRecord(
            rebirthNumber: rebirthCount + 1,
            levelAtRebirth: currentLevel,
            statsAtRebirth: currentStats,
            titlesPreserved: currentTitles,
            achievementsPreserved: currentAchievements
        )

        rebirthCount += 1
        records.append(record)
        recalculateBonuses()
        saveLocal()
        syncToRemote(record: record)

        return calculateStartingStats()
    }

    /// Calculate starting stats for the current rebirth level
    func calculateStartingStats() -> Stats {
        let bonus = startingStatBonus
        let base = Stats.baseline
        return Stats(
            strength: base.strength + bonus,
            discipline: base.discipline + bonus,
            focus: base.focus + bonus,
            energy: base.energy + bonus,
            wisdom: base.wisdom + bonus,
            mind: base.mind + bonus,
            spirit: base.spirit + bonus
        )
    }

    /// Apply XP bonus multiplier to earned XP
    func applyXPBonus(baseXP: Int) -> Int {
        Int(Double(baseXP) * xpBonusMultiplier)
    }

    /// Sync prestige data from remote on app launch
    func syncFromRemote(userID: UUID) async {
        guard let client = supabase.client else { return }

        do {
            struct PrestigeRow: Decodable {
                let rebirth_number: Int
                let performed_at: String
                let level_at_rebirth: Int
            }

            let rows: [PrestigeRow] = try await client
                .from("prestige_records")
                .select()
                .eq("user_id", value: userID.uuidString)
                .order("rebirth_number", ascending: true)
                .execute()
                .value

            if rows.count > records.count {
                rebirthCount = rows.count
                recalculateBonuses()
                saveLocal()
            }
        } catch {
            RNFLogger.challenge.error("PrestigeService: syncFromRemote failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers

    private func recalculateBonuses() {
        xpBonusMultiplier = 1.0 + (Double(rebirthCount) * Self.xpBonusPerRebirth)
        startingStatBonus = rebirthCount >= Self.statBonusMinRebirth ? rebirthCount - 1 : 0
    }

    // MARK: - Local Persistence

    private func loadLocal() {
        rebirthCount = userDefaults.integer(forKey: Self.rebirthCountKey)
        if let data = userDefaults.data(forKey: Self.recordsKey),
           let decoded = try? JSONDecoder().decode([RebirthRecord].self, from: data) {
            records = decoded
        }
    }

    private func saveLocal() {
        userDefaults.set(rebirthCount, forKey: Self.rebirthCountKey)
        if let data = try? JSONEncoder().encode(records) {
            userDefaults.set(data, forKey: Self.recordsKey)
        }
    }

    // MARK: - Remote Sync

    private func syncToRemote(record: RebirthRecord) {
        guard let client = supabase.client else { return }

        Task {
            do {
                let formatter = ISO8601DateFormatter()

                struct PrestigeUpsert: Encodable {
                    let rebirth_number: Int
                    let performed_at: String
                    let level_at_rebirth: Int
                    let titles_preserved: [String]
                    let achievements_preserved: [String]
                    let xp_bonus_percent: Int
                    let stat_bonus: Int
                }

                let upsert = PrestigeUpsert(
                    rebirth_number: record.rebirthNumber,
                    performed_at: formatter.string(from: record.performedAt),
                    level_at_rebirth: record.levelAtRebirth,
                    titles_preserved: record.titlesPreserved,
                    achievements_preserved: record.achievementsPreserved,
                    xp_bonus_percent: Int(xpBonusMultiplier * 100) - 100,
                    stat_bonus: startingStatBonus
                )

                try await client
                    .from("prestige_records")
                    .upsert(upsert)
                    .execute()
            } catch {
                RNFLogger.challenge.error("PrestigeService: syncToRemote failed — \(error.localizedDescription)")
            }
        }
    }
}
