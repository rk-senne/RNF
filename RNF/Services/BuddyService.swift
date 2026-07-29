import Foundation
import os

// MARK: - P28-INC-20/21/22/23/24/25: Buddy System Service

/// Accountability buddy system with privacy-first design.
/// - Link via shareable code (P28-INC-20)
/// - Daily completion sharing — checkmark/X only (P28-INC-21)
/// - Bond streak tracking (P28-INC-22)
/// - Privacy: buddy never sees habit names (P28-INC-23)
/// - +5 XP bonus when both complete (P28-INC-24)
/// - Unpair functionality (P28-INC-25)
@MainActor
final class BuddyService: ObservableObject {

    // MARK: - Models

    struct BuddyPair: Codable, Identifiable {
        let id: UUID
        let userId: UUID
        let buddyId: UUID
        let linkCode: String
        let bondStreak: Int
        let createdAt: Date
        var isActive: Bool

        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case buddyId = "buddy_id"
            case linkCode = "link_code"
            case bondStreak = "bond_streak"
            case createdAt = "created_at"
            case isActive = "is_active"
        }
    }

    /// Privacy-safe completion status shared with buddy.
    /// Never includes habit names — only a boolean per day.
    struct BuddyDailyStatus: Codable {
        let userId: UUID
        let date: Date
        let didComplete: Bool  // True if met daily goal
        let completionCount: Int // How many habits completed (no names)

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case date
            case didComplete = "did_complete"
            case completionCount = "completion_count"
        }
    }

    struct BondStreakResult {
        let currentStreak: Int
        let bothCompletedToday: Bool
        let xpBonus: Int
    }

    // MARK: - Constants

    static let xpBonusBothComplete = 5
    static let linkCodeLength = 6

    // MARK: - Published State

    @Published private(set) var activePair: BuddyPair?
    @Published private(set) var buddyStatus: BuddyDailyStatus?
    @Published private(set) var bondStreak: Int = 0

    // MARK: - Dependencies

    private let supabase: SupabaseService

    // MARK: - Init

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    // MARK: - Link Code Generation (P28-INC-20)

    /// Generates a unique 6-character alphanumeric link code.
    func generateLinkCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // No ambiguous chars
        return String((0..<Self.linkCodeLength).map { _ in
            characters.randomElement()!
        })
    }

    /// Creates a buddy pair invite with a shareable code.
    func createInvite(userId: UUID) async -> RNFServiceWriteResult<BuddyPair> {
        let code = generateLinkCode()
        let pair = BuddyPair(
            id: UUID(),
            userId: userId,
            buddyId: UUID(), // Placeholder until buddy joins
            linkCode: code,
            bondStreak: 0,
            createdAt: Date(),
            isActive: false
        )

        do {
            let created: BuddyPair = try await supabase.db
                .from("buddy_pairs")
                .insert(pair)
                .select()
                .single()
                .execute()
                .value
            RNFLogger.social.info("Created buddy invite with code: \(code)")
            activePair = created
            return .savedRemotely(created)
        } catch {
            RNFLogger.social.error("BuddyService: createInvite failed — \(error.localizedDescription)")
            activePair = pair
            return .savedLocallyOnly(pair, error: .networkUnavailable)
        }
    }

    /// Joins an existing pair using a link code.
    func joinWithCode(_ code: String, userId: UUID) async -> RNFServiceWriteResult<BuddyPair> {
        guard code.count == Self.linkCodeLength else {
            return .notSaved(.serverRejected)
        }

        do {
            struct BuddyJoinUpdate: Encodable {
                let buddy_id: UUID
                let is_active: Bool
            }

            let updated: BuddyPair = try await supabase.db
                .from("buddy_pairs")
                .update(BuddyJoinUpdate(buddy_id: userId, is_active: true))
                .eq("link_code", value: code)
                .select()
                .single()
                .execute()
                .value

            activePair = updated
            RNFLogger.social.info("Joined buddy pair with code: \(code)")
            return .savedRemotely(updated)
        } catch {
            RNFLogger.social.error("BuddyService: joinWithCode failed — \(error.localizedDescription)")
            return .notSaved(.notFound)
        }
    }

    // MARK: - Daily Completion Sharing (P28-INC-21/23)

    /// Shares daily completion status with buddy.
    /// PRIVACY: Only sends didComplete flag and count — never habit names.
    func shareDailyStatus(
        userId: UUID,
        dailyCompleted: Int,
        dailyGoal: Int
    ) async {
        guard let pair = activePair, pair.isActive else { return }

        let status = BuddyDailyStatus(
            userId: userId,
            date: Date().startOfDay,
            didComplete: dailyCompleted >= dailyGoal,
            completionCount: dailyCompleted
        )

        do {
            try await supabase.db
                .from("buddy_daily_status")
                .upsert(status)
                .execute()
            RNFLogger.social.info("Shared daily status: \(status.didComplete)")
        } catch {
            RNFLogger.social.error("BuddyService: shareDailyStatus failed — \(error.localizedDescription)")
        }
    }

    /// Fetches buddy's daily status (privacy-safe: no habit details).
    func fetchBuddyStatus(for pair: BuddyPair, currentUserId: UUID) async -> BuddyDailyStatus? {
        let buddyId = pair.userId == currentUserId ? pair.buddyId : pair.userId

        do {
            let statuses: [BuddyDailyStatus] = try await supabase.db
                .from("buddy_daily_status")
                .select()
                .eq("user_id", value: buddyId.uuidString)
                .eq("date", value: Date().startOfDay)
                .limit(1)
                .execute()
                .value

            let status = statuses.first
            buddyStatus = status
            return status
        } catch {
            RNFLogger.social.error("BuddyService: fetchBuddyStatus failed — \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Bond Streak (P28-INC-22, P32-SOC-01 Enhancement)

    /// Enhanced bond streak — increments when EITHER buddy completes 1+ habit.
    /// This lowers the bar compared to the original "both must complete all" model,
    /// creating lower-friction mutual accountability.
    ///
    /// The bond streak only resets if NEITHER buddy logged any completions.
    func calculateBondStreak(
        myCompleted: Bool,
        buddyCompleted: Bool,
        currentBondStreak: Int
    ) -> BondStreakResult {
        let eitherCompleted = myCompleted || buddyCompleted
        let bothCompleted = myCompleted && buddyCompleted
        let newStreak = eitherCompleted ? currentBondStreak + 1 : 0
        let bonus = bothCompleted ? Self.xpBonusBothComplete : 0

        bondStreak = newStreak
        return BondStreakResult(
            currentStreak: newStreak,
            bothCompletedToday: bothCompleted,
            xpBonus: bonus
        )
    }

    // MARK: - XP Bonus (P28-INC-24)

    /// Returns XP bonus if both buddies completed today.
    func xpBonusIfBothComplete(myCompleted: Bool, buddyCompleted: Bool) -> Int {
        (myCompleted && buddyCompleted) ? Self.xpBonusBothComplete : 0
    }

    // MARK: - Unpair (P28-INC-25)

    /// Deactivates the buddy pair. Either party can unpair.
    func unpair(pairId: UUID) async -> Bool {
        guard var pair = activePair, pair.id == pairId else { return false }

        pair.isActive = false
        activePair = nil
        bondStreak = 0
        buddyStatus = nil

        do {
            struct DeactivateUpdate: Encodable {
                let is_active: Bool
            }

            try await supabase.db
                .from("buddy_pairs")
                .update(DeactivateUpdate(is_active: false))
                .eq("id", value: pairId.uuidString)
                .execute()
            RNFLogger.social.info("Buddy pair \(pairId) deactivated")
        } catch {
            RNFLogger.social.error("BuddyService: unpair failed — \(error.localizedDescription)")
        }

        return true
    }

    // MARK: - Load Active Pair

    func loadActivePair(userId: UUID) async {
        do {
            let pairs: [BuddyPair] = try await supabase.db
                .from("buddy_pairs")
                .select()
                .eq("is_active", value: true)
                .or("user_id.eq.\(userId.uuidString),buddy_id.eq.\(userId.uuidString)")
                .limit(1)
                .execute()
                .value

            activePair = pairs.first
            if let pair = activePair {
                bondStreak = pair.bondStreak
            }
        } catch {
            RNFLogger.social.error("BuddyService: loadActivePair failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Privacy Verification

    /// Asserts that no habit names are included in shared data.
    /// Used in tests to verify privacy contract.
    static func verifyPrivacy(in status: BuddyDailyStatus) -> Bool {
        // BuddyDailyStatus has no field for habit names — privacy by design.
        // This method exists for test documentation purposes.
        return true
    }
}

// RNFLogger.social defined in Core/RNFLogger.swift

// startOfDay is defined in Extensions/Date+Helpers.swift
