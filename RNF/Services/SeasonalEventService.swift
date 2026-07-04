import Foundation

// P27-LIF-28/29/30/31/32: Seasonal Event system
// Quarterly opt-in events with progress tracking and reward distribution.
// Awakening (spring), Crucible (summer), Harvest (autumn), Deep Forge (winter)

@MainActor
final class SeasonalEventService: ObservableObject {

    // MARK: - Types

    enum Season: String, Codable, CaseIterable {
        case spring
        case summer
        case autumn
        case winter

        var eventName: String {
            switch self {
            case .spring: return "Awakening"
            case .summer: return "Crucible"
            case .autumn: return "Harvest"
            case .winter: return "Deep Forge"
            }
        }

        var description: String {
            switch self {
            case .spring: return "Renewal and new beginnings — focus on starting fresh habits"
            case .summer: return "Intensity and heat — push your limits with challenging goals"
            case .autumn: return "Reap what you sowed — consolidate gains and build consistency"
            case .winter: return "Deep inner work — mastery through patience and reflection"
            }
        }

        var months: [Int] {
            switch self {
            case .spring: return [3, 4, 5]
            case .summer: return [6, 7, 8]
            case .autumn: return [9, 10, 11]
            case .winter: return [12, 1, 2]
            }
        }

        var bonusStat: String {
            switch self {
            case .spring: return "energy"
            case .summer: return "strength"
            case .autumn: return "wisdom"
            case .winter: return "focus"
            }
        }

        var rewardTitle: String {
            switch self {
            case .spring: return "Awakened"
            case .summer: return "Crucible Survivor"
            case .autumn: return "Harvester"
            case .winter: return "Deep Forged"
            }
        }

        var rewardTokens: Int { 50 }
        var rewardXP: Int { 500 }

        static func current(date: Date = Date()) -> Season {
            let month = Calendar.current.component(.month, from: date)
            switch month {
            case 3, 4, 5: return .spring
            case 6, 7, 8: return .summer
            case 9, 10, 11: return .autumn
            default: return .winter
            }
        }
    }

    struct EventParticipation: Codable, Identifiable {
        let id: UUID
        let season: Season
        let year: Int
        let optedInAt: Date
        var progress: Double
        var completedAt: Date?
        var rewardClaimed: Bool

        var isComplete: Bool { completedAt != nil }

        init(season: Season, year: Int) {
            self.id = UUID()
            self.season = season
            self.year = year
            self.optedInAt = Date()
            self.progress = 0.0
            self.completedAt = nil
            self.rewardClaimed = false
        }
    }

    struct EventReward {
        let title: String
        let tokens: Int
        let xp: Int
        let badgeID: String
    }

    // MARK: - Published State

    @Published private(set) var currentSeason: Season = .spring
    @Published private(set) var activeParticipation: EventParticipation?
    @Published private(set) var participationHistory: [EventParticipation] = []
    @Published private(set) var isOptedIn: Bool = false

    // MARK: - Dependencies

    private let supabase: SupabaseService
    private let userDefaults: UserDefaults

    // MARK: - UserDefaults Keys

    private static let participationKey = "rnf_seasonal_event_participation"
    private static let historyKey = "rnf_seasonal_event_history"

    // MARK: - Constants

    static let completionThreshold: Double = 1.0
    static let progressPerAction: Double = 1.0 / 90.0 // ~90 actions to complete

    // MARK: - Init

    init(supabase: SupabaseService = .shared, userDefaults: UserDefaults = .standard) {
        self.supabase = supabase
        self.userDefaults = userDefaults
        currentSeason = Season.current()
        loadLocal()
    }

    // MARK: - Public API

    /// Opt in to the current seasonal event
    func optIn() {
        guard activeParticipation == nil else { return }

        let year = Calendar.current.component(.year, from: Date())
        let participation = EventParticipation(season: currentSeason, year: year)
        activeParticipation = participation
        isOptedIn = true
        saveLocal()
        syncOptInToRemote()
    }

    /// Opt out of the current seasonal event
    func optOut() {
        activeParticipation = nil
        isOptedIn = false
        saveLocal()
    }

    /// Record progress from a completed action
    func recordProgress(amount: Double = SeasonalEventService.progressPerAction) {
        guard var participation = activeParticipation, !participation.isComplete else { return }

        participation.progress = min(participation.progress + amount, Self.completionThreshold)

        if participation.progress >= Self.completionThreshold {
            participation.completedAt = Date()
        }

        activeParticipation = participation
        saveLocal()
        syncProgressToRemote()
    }

    /// Claim rewards for a completed event
    func claimReward() -> EventReward? {
        guard var participation = activeParticipation,
              participation.isComplete,
              !participation.rewardClaimed else { return nil }

        participation.rewardClaimed = true
        activeParticipation = participation
        participationHistory.append(participation)
        saveLocal()
        syncRewardClaimToRemote()

        return EventReward(
            title: currentSeason.rewardTitle,
            tokens: currentSeason.rewardTokens,
            xp: currentSeason.rewardXP,
            badgeID: "seasonal_\(currentSeason.rawValue)_\(participation.year)"
        )
    }

    /// Check if the current season has changed and archive old participation
    func refreshSeason() {
        let newSeason = Season.current()
        guard newSeason != currentSeason else { return }

        // Archive any unclaimed active participation
        if let active = activeParticipation {
            participationHistory.append(active)
            activeParticipation = nil
            isOptedIn = false
        }

        currentSeason = newSeason
        saveLocal()
    }

    /// Check if player has completed a specific seasonal event
    func hasCompleted(season: Season, year: Int) -> Bool {
        participationHistory.contains {
            $0.season == season && $0.year == year && $0.isComplete
        }
    }

    /// Sync from remote on app launch
    func syncFromRemote(userID: UUID) async {
        guard let client = supabase.client else { return }

        do {
            struct EventRow: Decodable {
                let season: String
                let year: Int
                let progress: Double
                let completed_at: String?
                let reward_claimed: Bool
            }

            let rows: [EventRow] = try await client
                .from("seasonal_events")
                .select()
                .eq("user_id", value: userID.uuidString)
                .order("year", ascending: false)
                .execute()
                .value

            if rows.count > participationHistory.count {
                saveLocal()
            }
        } catch {
            RNFLogger.challenge.error("SeasonalEventService: syncFromRemote failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Local Persistence

    private func loadLocal() {
        if let data = userDefaults.data(forKey: Self.participationKey),
           let participation = try? JSONDecoder().decode(EventParticipation.self, from: data) {
            activeParticipation = participation
            isOptedIn = true
        }

        if let data = userDefaults.data(forKey: Self.historyKey),
           let history = try? JSONDecoder().decode([EventParticipation].self, from: data) {
            participationHistory = history
        }
    }

    private func saveLocal() {
        if let participation = activeParticipation,
           let data = try? JSONEncoder().encode(participation) {
            userDefaults.set(data, forKey: Self.participationKey)
        } else {
            userDefaults.removeObject(forKey: Self.participationKey)
        }

        if let data = try? JSONEncoder().encode(participationHistory) {
            userDefaults.set(data, forKey: Self.historyKey)
        }
    }

    // MARK: - Remote Sync

    private func syncOptInToRemote() {
        guard let client = supabase.client else { return }

        Task {
            do {
                struct EventInsert: Encodable {
                    let season: String
                    let year: Int
                    let opted_in_at: String
                    let progress: Double
                }

                let formatter = ISO8601DateFormatter()
                let insert = EventInsert(
                    season: currentSeason.rawValue,
                    year: Calendar.current.component(.year, from: Date()),
                    opted_in_at: formatter.string(from: Date()),
                    progress: 0.0
                )

                try await client
                    .from("seasonal_events")
                    .insert(insert)
                    .execute()
            } catch {
                RNFLogger.challenge.error("SeasonalEventService: syncOptIn failed — \(error.localizedDescription)")
            }
        }
    }

    private func syncProgressToRemote() {
        guard let client = supabase.client,
              let participation = activeParticipation else { return }

        Task {
            do {
                struct ProgressUpdate: Encodable {
                    let progress: Double
                    let completed_at: String?
                }

                let formatter = ISO8601DateFormatter()
                let update = ProgressUpdate(
                    progress: participation.progress,
                    completed_at: participation.completedAt.map { formatter.string(from: $0) }
                )

                try await client
                    .from("seasonal_events")
                    .update(update)
                    .eq("season", value: currentSeason.rawValue)
                    .eq("year", value: String(participation.year))
                    .execute()
            } catch {
                RNFLogger.challenge.error("SeasonalEventService: syncProgress failed — \(error.localizedDescription)")
            }
        }
    }

    private func syncRewardClaimToRemote() {
        guard let client = supabase.client,
              let participation = activeParticipation else { return }

        Task {
            do {
                struct RewardUpdate: Encodable {
                    let reward_claimed: Bool
                    let reward_claimed_at: String
                }

                let formatter = ISO8601DateFormatter()
                let update = RewardUpdate(
                    reward_claimed: true,
                    reward_claimed_at: formatter.string(from: Date())
                )

                try await client
                    .from("seasonal_events")
                    .update(update)
                    .eq("season", value: currentSeason.rawValue)
                    .eq("year", value: String(participation.year))
                    .execute()
            } catch {
                RNFLogger.challenge.error("SeasonalEventService: syncRewardClaim failed — \(error.localizedDescription)")
            }
        }
    }
}
