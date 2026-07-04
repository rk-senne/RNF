import Foundation
import os
import Security
import StoreKit

// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable, Sendable {
    case free
    case proMonthly
    case proYearly
    case proLifetime

    var isPro: Bool {
        self != .free
    }
}

// MARK: - Subscription Manager

@MainActor
final class SubscriptionManager: ObservableObject {

    // MARK: - Published State

    @Published private(set) var availableProducts: [Product] = []
    @Published private(set) var currentTier: SubscriptionTier = .free
    @Published private(set) var proEntitlement: Bool = false
    @Published private(set) var expirationDate: Date?
    @Published private(set) var isInGracePeriod: Bool = false
    @Published private(set) var isInBillingRetry: Bool = false
    @Published private(set) var purchaseInProgress: Bool = false

    // MARK: - Product IDs

    static let productIDs: Set<String> = [
        "com.rnf.pro.monthly",
        "com.rnf.pro.yearly",
        "com.rnf.pro.lifetime"
    ]

    static let subscriptionGroupID = "com.rnf.pro"

    // MARK: - Private

    private static let logger = Logger(subsystem: "com.rnf.app", category: "subscription")
    private var transactionListener: Task<Void, Error>?
    private let keychainService = "com.rnf.subscription"

    // MARK: - Initialization

    init() {
        transactionListener = listenForTransactions()

        Task {
            await loadProducts()
            await resolveEntitlements()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product Loading

    func loadProducts() async {
        do {
            let products = try await Product.products(for: Self.productIDs)
            availableProducts = products.sorted { lhs, rhs in
                lhs.price < rhs.price
            }
            Self.logger.info("Loaded \(products.count) products")
        } catch {
            Self.logger.error("Failed to load products: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase Flow

    func purchase(_ product: Product) async throws -> Transaction? {
        guard !purchaseInProgress else { return nil }
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        Self.logger.info("Starting purchase for \(product.id)")

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try verifyTransaction(verification)
            await transaction.finish()
            await resolveEntitlements()
            Self.logger.info("Purchase successful: \(transaction.productID)")
            return transaction

        case .userCancelled:
            Self.logger.info("User cancelled purchase")
            return nil

        case .pending:
            Self.logger.info("Purchase pending (Ask to Buy or SCA)")
            return nil

        @unknown default:
            Self.logger.warning("Unknown purchase result")
            return nil
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        Self.logger.info("Restoring purchases")
        try? await AppStore.sync()
        await resolveEntitlements()
    }

    // MARK: - Entitlement Resolution

    /// Resolves entitlements using Transaction.currentEntitlements.
    /// Checks for active subscriptions and non-consumable lifetime purchases.
    func resolveEntitlements() async {
        var foundEntitlement = false
        var detectedTier: SubscriptionTier = .free
        var detectedExpiry: Date?
        var gracePeriod = false
        var billingRetry = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard Self.productIDs.contains(transaction.productID) else { continue }
            guard transaction.revocationDate == nil else { continue }

            // Check expiration (subscriptions only; lifetime has no expiry)
            if let expiry = transaction.expirationDate, expiry < .now {
                continue
            }

            foundEntitlement = true
            detectedExpiry = transaction.expirationDate

            switch transaction.productID {
            case "com.rnf.pro.lifetime":
                detectedTier = .proLifetime
            case "com.rnf.pro.yearly":
                detectedTier = .proYearly
            case "com.rnf.pro.monthly":
                // Don't downgrade if we already found yearly or lifetime
                if detectedTier == .free {
                    detectedTier = .proMonthly
                }
            default:
                break
            }

            // Check grace period and billing retry via subscription status
            if let subscriptionStatus = await fetchSubscriptionStatus(for: transaction) {
                switch subscriptionStatus.state {
                case .inGracePeriod:
                    gracePeriod = true
                case .inBillingRetryPeriod:
                    billingRetry = true
                default:
                    break
                }
            }
        }

        proEntitlement = foundEntitlement
        currentTier = detectedTier
        expirationDate = detectedExpiry
        isInGracePeriod = gracePeriod
        isInBillingRetry = billingRetry

        // Persist to Keychain for offline access
        persistSubscriptionState(isPro: foundEntitlement, tier: detectedTier)

        Self.logger.info(
            "Entitlement resolved: tier=\(detectedTier.rawValue), pro=\(foundEntitlement), grace=\(gracePeriod), retry=\(billingRetry)"
        )
    }

    // MARK: - Transaction Updates Listener

    /// Listens for real-time transaction updates (renewals, revocations, refunds).
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }

                do {
                    let transaction = try await self.verifyTransaction(result)
                    await transaction.finish()
                    await self.resolveEntitlements()
                    Self.logger.info("Transaction update processed: \(transaction.productID)")
                } catch {
                    Self.logger.error("Transaction update verification failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Subscription Status

    private func fetchSubscriptionStatus(
        for transaction: Transaction
    ) async -> Product.SubscriptionInfo.Status? {
        guard let product = availableProducts.first(where: { $0.id == transaction.productID }) else {
            return nil
        }

        guard let subscription = product.subscription else { return nil }

        do {
            let statuses = try await subscription.status
            return statuses.first { status in
                guard case .verified(let renewalInfo) = status.renewalInfo else { return false }
                return renewalInfo.originalTransactionID == transaction.originalID
            }
        } catch {
            Self.logger.error("Failed to fetch subscription status: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Transaction Verification

    private func verifyTransaction(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified(_, let error):
            Self.logger.error("Transaction verification failed: \(error.localizedDescription)")
            throw SubscriptionError.verificationFailed
        }
    }

    // MARK: - Keychain Persistence

    /// Persists subscription state to Keychain for offline entitlement checks.
    private func persistSubscriptionState(isPro: Bool, tier: SubscriptionTier) {
        let state = CachedSubscriptionState(
            isPro: isPro,
            tier: tier,
            lastChecked: Date()
        )

        guard let data = try? JSONEncoder().encode(state) else {
            Self.logger.error("Failed to encode subscription state for Keychain")
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "subscription_state"
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = data
            SecItemAdd(newItem as CFDictionary, nil)
        } else if status != errSecSuccess {
            Self.logger.error("Keychain write failed: \(status)")
        }
    }

    /// Reads cached subscription state from Keychain (for offline use).
    func cachedSubscriptionState() -> CachedSubscriptionState? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "subscription_state",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }

        return try? JSONDecoder().decode(CachedSubscriptionState.self, from: data)
    }

    // MARK: - Convenience

    /// Returns true if user has Pro access (including grace period and billing retry).
    var hasProAccess: Bool {
        proEntitlement || isInGracePeriod || isInBillingRetry
    }

    /// Returns the monthly product for display.
    var monthlyProduct: Product? {
        availableProducts.first { $0.id == "com.rnf.pro.monthly" }
    }

    /// Returns the yearly product for display.
    var yearlyProduct: Product? {
        availableProducts.first { $0.id == "com.rnf.pro.yearly" }
    }

    /// Returns the lifetime product for display.
    var lifetimeProduct: Product? {
        availableProducts.first { $0.id == "com.rnf.pro.lifetime" }
    }
}

// MARK: - Supporting Types

struct CachedSubscriptionState: Codable {
    let isPro: Bool
    let tier: SubscriptionTier
    let lastChecked: Date

    /// Cache is considered stale after 1 hour.
    var isStale: Bool {
        Date().timeIntervalSince(lastChecked) > 3600
    }
}

enum SubscriptionError: Error, LocalizedError {
    case verificationFailed
    case productNotFound
    case purchaseFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Transaction verification failed. Please try again."
        case .productNotFound:
            return "Subscription product not found."
        case .purchaseFailed:
            return "Purchase could not be completed."
        }
    }
}
