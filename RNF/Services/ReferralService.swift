import Foundation

// P24-GRO-05: Referral system
// Code generation, validation, and reward distribution
// Reward: +1 forgiveness token + 5 forge tokens on referred user's Day 3

@MainActor
final class ReferralService: ObservableObject {

    // MARK: - Types

    struct Referral: Codable, Identifiable {
        let id: UUID
        let referrer_id: UUID
        let referred_id: UUID?
        let code: String
        let created_at: Date
        var redeemed_at: Date?
        var reward_distributed: Bool

        init(referrerID: UUID, code: String) {
            self.id = UUID()
            self.referrer_id = referrerID
            self.referred_id = nil
            self.code = code
            self.created_at = Date()
            self.redeemed_at = nil
            self.reward_distributed = false
        }
    }

    struct ReferralReward {
        static let forgivenessTokens = 1
        static let forgeTokens = 5
        static let rewardTriggerDay = 3
    }

    enum ValidationResult {
        case valid(referrerID: UUID)
        case invalid
        case expired
        case alreadyUsed
        case selfReferral
    }

    // MARK: - Published State

    @Published private(set) var myCode: String?
    @Published private(set) var referralCount: Int = 0

    // MARK: - Dependencies

    private let supabase: SupabaseService
    private let userDefaults: UserDefaults

    // MARK: - Keys

    private static let codeKey = "rnf_referral_code"
    private static let countKey = "rnf_referral_count"

    // MARK: - Init

    init(supabase: SupabaseService = .shared, userDefaults: UserDefaults = .standard) {
        self.supabase = supabase
        self.userDefaults = userDefaults
        loadLocal()
    }

    // MARK: - Code Generation

    /// Generate a unique 8-character alphanumeric referral code
    func generateCode(for userID: UUID) -> String {
        if let existing = myCode { return existing }

        let code = Self.createCode()
        myCode = code
        userDefaults.set(code, forKey: Self.codeKey)

        if let client = supabase.client {
            Task {
                do {
                    let referral = Referral(referrerID: userID, code: code)
                    try await client
                        .from("referrals")
                        .insert(referral)
                        .execute()
                } catch {
                    RNFLogger.auth.error("ReferralService: generateCode sync failed — \(error.localizedDescription)")
                }
            }
        }

        return code
    }

    /// Create an 8-character alphanumeric code (no I/O/0/1 to avoid confusion)
    static func createCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }

    // MARK: - Validation

    /// Validate a referral code entered by a new user
    func validate(code: String, currentUserID: UUID) async -> ValidationResult {
        guard let client = supabase.client else { return .invalid }

        do {
            struct ReferralRow: Decodable {
                let id: UUID
                let referrer_id: UUID
                let referred_id: UUID?
            }

            let rows: [ReferralRow] = try await client
                .from("referrals")
                .select("id, referrer_id, referred_id")
                .eq("code", value: code.uppercased())
                .limit(1)
                .execute()
                .value

            guard let referral = rows.first else { return .invalid }
            if referral.referrer_id == currentUserID { return .selfReferral }
            if referral.referred_id != nil { return .alreadyUsed }

            return .valid(referrerID: referral.referrer_id)
        } catch {
            RNFLogger.auth.error("ReferralService: validate failed — \(error.localizedDescription)")
            return .invalid
        }
    }

    /// Redeem a referral code (called when new user enters a code)
    func redeem(code: String, referredUserID: UUID) async -> Bool {
        guard let client = supabase.client else { return false }

        do {
            struct RedeemUpdate: Encodable {
                let referred_id: String
                let redeemed_at: String
            }

            let formatter = ISO8601DateFormatter()
            let update = RedeemUpdate(
                referred_id: referredUserID.uuidString,
                redeemed_at: formatter.string(from: Date())
            )

            try await client
                .from("referrals")
                .update(update)
                .eq("code", value: code.uppercased())
                .execute()

            return true
        } catch {
            RNFLogger.auth.error("ReferralService: redeem failed — \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Reward Distribution

    /// Check if referred user hit Day 3 and distribute rewards to referrer.
    func checkAndDistributeRewards(
        referredUserID: UUID,
        daysSinceJoin: Int,
        forgeTokenService: ForgeTokenService
    ) async {
        guard daysSinceJoin >= ReferralReward.rewardTriggerDay else { return }
        guard let client = supabase.client else { return }

        do {
            struct RewardCheck: Decodable {
                let id: UUID
                let referrer_id: UUID
                let reward_distributed: Bool
            }

            let rows: [RewardCheck] = try await client
                .from("referrals")
                .select("id, referrer_id, reward_distributed")
                .eq("referred_id", value: referredUserID.uuidString)
                .eq("reward_distributed", value: false)
                .limit(1)
                .execute()
                .value

            guard let pending = rows.first else { return }

            // Distribute forge token rewards to referrer
            forgeTokenService.earn(
                amount: ReferralReward.forgeTokens,
                reason: "Referral reward — friend reached Day 3"
            )

            // Mark reward as distributed
            struct RewardUpdate: Encodable {
                let reward_distributed: Bool
            }
            try await client
                .from("referrals")
                .update(RewardUpdate(reward_distributed: true))
                .eq("id", value: pending.id.uuidString)
                .execute()

            referralCount += 1
            userDefaults.set(referralCount, forKey: Self.countKey)
        } catch {
            RNFLogger.auth.error("ReferralService: checkAndDistributeRewards failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Local Persistence

    private func loadLocal() {
        myCode = userDefaults.string(forKey: Self.codeKey)
        referralCount = userDefaults.integer(forKey: Self.countKey)
    }
}
