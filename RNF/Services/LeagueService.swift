import Foundation

// P24-RET-22/23: Competitive league system
// Weekly XP-based leagues with promotion/demotion

@MainActor
final class LeagueService: ObservableObject {

    // MARK: - Types

    enum Tier: String, Codable, CaseIterable, Comparable {
        case bronze = "Bronze"
        case silver = "Silver"
        case gold = "Gold"
        case platinum = "Platinum"
        case diamond = "Diamond"

        var icon: String {
            switch self {
            case .bronze: return "🥉"
            case .silver: return "🥈"
            case .gold: return "🥇"
            case .platinum: return "💎"
            case .diamond: return "👑"
            }
        }

        var promotionThreshold: Int { 5 }
        var demotionThreshold: Int { 5 }

        static func < (lhs: Tier, rhs: Tier) -> Bool {
            let order: [Tier] = [.bronze, .silver, .gold, .platinum, .diamond]
            guard let l = order.firstIndex(of: lhs),
                  let r = order.firstIndex(of: rhs) else { return false }
            return l < r
        }

        var next: Tier? {
            switch self {
            case .bronze: return .silver
            case .silver: return .gold
            case .gold: return .platinum
            case .platinum: return .diamond
            case .diamond: return nil
            }
        }

        var previous: Tier? {
            switch self {
            case .bronze: return nil
            case .silver: return .bronze
            case .gold: return .silver
            case .platinum: return .gold
            case .diamond: return .platinum
            }
        }
    }

    struct LeagueMember: Codable, Identifiable {
        let id: UUID
        let user_id: UUID
        let display_name: String?
        var weekly_xp: Int
        var tier: Tier
        var rank: Int?
    }

    struct LeagueStanding: Codable {
        let tier: Tier
        let rank: Int
        let totalMembers: Int
        let weeklyXP: Int
        let willPromote: Bool
        let willDemote: Bool
    }

    // MARK: - Published State

    @Published private(set) var currentTier: Tier = .bronze
    @Published private(set) var standing: LeagueStanding?
    @Published private(set) var leaderboard: [LeagueMember] = []
    @Published private(set) var isJoined: Bool = false

    // MARK: - Dependencies

    private let supabase: SupabaseService
    private let userDefaults: UserDefaults

    // MARK: - Keys

    private static let tierKey = "rnf_league_tier"
    private static let joinedKey = "rnf_league_joined"
    private static let weeklyXPKey = "rnf_league_weekly_xp"

    // MARK: - Init

    init(supabase: SupabaseService = .shared, userDefaults: UserDefaults = .standard) {
        self.supabase = supabase
        self.userDefaults = userDefaults
        loadLocal()
    }

    // MARK: - Public API

    /// Join the league system. Places user in Bronze tier.
    func join(userID: UUID, displayName: String?) async -> RNFServiceWriteResult<LeagueMember> {
        let member = LeagueMember(
            id: UUID(),
            user_id: userID,
            display_name: displayName,
            weekly_xp: 0,
            tier: .bronze,
            rank: nil
        )

        isJoined = true
        currentTier = .bronze
        saveLocal()

        guard let client = supabase.client else {
            return .savedLocallyOnly(member, error: .networkUnavailable)
        }

        do {
            let created: LeagueMember = try await client
                .from("league_members")
                .insert(member)
                .select()
                .single()
                .execute()
                .value
            return .savedRemotely(created)
        } catch {
            RNFLogger.auth.error("LeagueService: join failed — \(error.localizedDescription)")
            return .savedLocallyOnly(member, error: .unknown)
        }
    }

    /// Report XP earned this week for league ranking
    func reportWeeklyXP(userID: UUID, xpGained: Int) async {
        guard isJoined, let client = supabase.client else { return }

        let currentWeeklyXP = userDefaults.integer(forKey: Self.weeklyXPKey) + xpGained
        userDefaults.set(currentWeeklyXP, forKey: Self.weeklyXPKey)

        do {
            struct XPUpdate: Encodable {
                let weekly_xp: Int
            }
            try await client
                .from("league_members")
                .update(XPUpdate(weekly_xp: currentWeeklyXP))
                .eq("user_id", value: userID.uuidString)
                .execute()
        } catch {
            RNFLogger.auth.error("LeagueService: reportWeeklyXP failed — \(error.localizedDescription)")
        }
    }

    /// Fetch current league standings from server
    func fetchStandings(userID: UUID) async {
        guard let client = supabase.client else { return }

        do {
            let members: [LeagueMember] = try await client
                .from("league_members")
                .select()
                .eq("tier", value: currentTier.rawValue)
                .order("weekly_xp", ascending: false)
                .execute()
                .value

            leaderboard = members.enumerated().map { index, member in
                var m = member
                m.rank = index + 1
                return m
            }

            if let userIndex = leaderboard.firstIndex(where: { $0.user_id == userID }) {
                let rank = userIndex + 1
                let total = leaderboard.count
                standing = LeagueStanding(
                    tier: currentTier,
                    rank: rank,
                    totalMembers: total,
                    weeklyXP: leaderboard[userIndex].weekly_xp,
                    willPromote: rank <= currentTier.promotionThreshold,
                    willDemote: rank > (total - currentTier.demotionThreshold)
                )
            }
        } catch {
            RNFLogger.auth.error("LeagueService: fetchStandings failed — \(error.localizedDescription)")
        }
    }

    /// Process end-of-week promotion/demotion
    func processWeekEnd(userID: UUID) async -> Tier {
        guard let currentStanding = standing else { return currentTier }

        var newTier = currentTier

        if currentStanding.willPromote, let next = currentTier.next {
            newTier = next
        } else if currentStanding.willDemote, let prev = currentTier.previous {
            newTier = prev
        }

        if newTier != currentTier {
            currentTier = newTier
            saveLocal()
            userDefaults.set(0, forKey: Self.weeklyXPKey)

            if let client = supabase.client {
                do {
                    struct TierUpdate: Encodable {
                        let tier: String
                        let weekly_xp: Int
                    }
                    try await client
                        .from("league_members")
                        .update(TierUpdate(tier: newTier.rawValue, weekly_xp: 0))
                        .eq("user_id", value: userID.uuidString)
                        .execute()
                } catch {
                    RNFLogger.auth.error("LeagueService: processWeekEnd sync failed — \(error.localizedDescription)")
                }
            }
        }

        return newTier
    }

    /// Query user's current tier
    func currentLeagueTier() -> Tier {
        currentTier
    }

    // MARK: - Local Persistence

    private func loadLocal() {
        isJoined = userDefaults.bool(forKey: Self.joinedKey)
        if let tierString = userDefaults.string(forKey: Self.tierKey),
           let tier = Tier(rawValue: tierString) {
            currentTier = tier
        }
    }

    private func saveLocal() {
        userDefaults.set(isJoined, forKey: Self.joinedKey)
        userDefaults.set(currentTier.rawValue, forKey: Self.tierKey)
    }
}
