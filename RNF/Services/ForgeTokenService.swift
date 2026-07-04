import Foundation

// P24-RET-13/14: Forge Token economy service
// Local-first with Supabase sync for persistence

@MainActor
final class ForgeTokenService: ObservableObject {

    // MARK: - Types

    enum TransactionType: String, Codable {
        case earned
        case spent
    }

    struct Transaction: Codable, Identifiable {
        let id: UUID
        let type: TransactionType
        let amount: Int
        let reason: String
        let date: Date

        init(type: TransactionType, amount: Int, reason: String, date: Date = Date()) {
            self.id = UUID()
            self.type = type
            self.amount = amount
            self.reason = reason
            self.date = date
        }
    }

    // MARK: - Published State

    @Published private(set) var balance: Int = 0
    @Published private(set) var transactions: [Transaction] = []

    // MARK: - Dependencies

    private let supabase: SupabaseService
    private let userDefaults: UserDefaults

    // MARK: - UserDefaults Keys

    private static let balanceKey = "rnf_forge_token_balance"
    private static let ledgerKey = "rnf_forge_token_ledger"

    // MARK: - Init

    init(supabase: SupabaseService = .shared, userDefaults: UserDefaults = .standard) {
        self.supabase = supabase
        self.userDefaults = userDefaults
        loadLocal()
    }

    // MARK: - Public API

    /// Earn tokens for an action (streak bonus, challenge win, etc.)
    func earn(amount: Int, reason: String) {
        guard amount > 0 else { return }

        let transaction = Transaction(type: .earned, amount: amount, reason: reason)
        balance += amount
        transactions.append(transaction)
        saveLocal()
        syncToRemote(transaction: transaction)
    }

    /// Spend tokens on a reward. Returns true if successful.
    @discardableResult
    func spend(amount: Int, reason: String) -> Bool {
        guard amount > 0, balance >= amount else { return false }

        let transaction = Transaction(type: .spent, amount: amount, reason: reason)
        balance -= amount
        transactions.append(transaction)
        saveLocal()
        syncToRemote(transaction: transaction)
        return true
    }

    /// Check if user can afford a cost
    func canAfford(_ cost: Int) -> Bool {
        balance >= cost
    }

    /// Refresh balance from remote (on app launch or pull-to-refresh)
    func syncFromRemote(userID: UUID) async {
        guard let client = supabase.client else { return }

        do {
            struct TokenRow: Decodable {
                let balance: Int
            }
            let rows: [TokenRow] = try await client
                .from("forge_tokens")
                .select("balance")
                .eq("user_id", value: userID.uuidString)
                .limit(1)
                .execute()
                .value

            if let remote = rows.first {
                if remote.balance != balance {
                    balance = remote.balance
                    saveLocal()
                }
            }
        } catch {
            RNFLogger.auth.error("ForgeTokenService: syncFromRemote failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Local Persistence

    private func loadLocal() {
        balance = userDefaults.integer(forKey: Self.balanceKey)

        if let data = userDefaults.data(forKey: Self.ledgerKey),
           let ledger = try? JSONDecoder().decode([Transaction].self, from: data) {
            transactions = ledger
        }
    }

    private func saveLocal() {
        userDefaults.set(balance, forKey: Self.balanceKey)

        let trimmed = Array(transactions.suffix(100))
        if let data = try? JSONEncoder().encode(trimmed) {
            userDefaults.set(data, forKey: Self.ledgerKey)
        }
    }

    // MARK: - Remote Sync

    private func syncToRemote(transaction: Transaction) {
        guard let client = supabase.client else { return }

        Task {
            do {
                struct TokenUpdate: Encodable {
                    let balance: Int
                    let last_transaction_reason: String
                    let updated_at: String
                }

                let formatter = ISO8601DateFormatter()
                let update = TokenUpdate(
                    balance: balance,
                    last_transaction_reason: transaction.reason,
                    updated_at: formatter.string(from: Date())
                )

                try await client
                    .from("forge_tokens")
                    .upsert(update)
                    .execute()
            } catch {
                RNFLogger.auth.error("ForgeTokenService: syncToRemote failed — \(error.localizedDescription)")
            }
        }
    }
}
