import Foundation
import PostgREST
import StoreKit
import Supabase

enum SubscriptionPlanType: String, Codable {
    case fullAccess = "full_access"
    case maintenance
}

enum SubscriptionStatus: String, Codable {
    case active
    case expired
}

struct SubscriptionEntitlement {
    let productID: String
    let expirationDate: Date?
}

final class SubscriptionService {

    private let supabase: SupabaseService
    private let productIDs: Set<String>
    private let analyticsService: AnalyticsService
    private let authProvider: AuthProviding

    init(
        supabase: SupabaseService = .shared,
        productIDs: Set<String> = [],
        analyticsService: AnalyticsService = AnalyticsService(),
        authProvider: AuthProviding? = nil
    ) {
        self.supabase = supabase
        self.productIDs = productIDs
        self.analyticsService = analyticsService
        self.authProvider = authProvider ?? AuthService(supabase: supabase)
    }

    func getSubscriptionState() async {
        _ = supabase
        _ = productIDs
    }

    func fetchProducts() async throws -> [Product] {
        try await Product.products(for: productIDs)
    }

    func validateEntitlement() async -> SubscriptionEntitlement? {
        guard productIDs.isEmpty == false else { return nil }

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard productIDs.contains(transaction.productID) else { continue }
            guard transaction.revocationDate == nil else { continue }

            if let expirationDate = transaction.expirationDate, expirationDate < .now {
                continue
            }

            return SubscriptionEntitlement(
                productID: transaction.productID,
                expirationDate: transaction.expirationDate
            )
        }

        return nil
    }

    func syncSubscription(userId: UUID) async throws {
        let entitlement = await validateEntitlement()

        struct SubscriptionUpdate: Encodable {
            let plan_type: SubscriptionPlanType
            let status: SubscriptionStatus
            let renewal_date: Date?
        }

        let update = SubscriptionUpdate(
            plan_type: entitlement == nil ? .maintenance : .fullAccess,
            status: entitlement == nil ? .expired : .active,
            renewal_date: entitlement?.expirationDate
        )

        try await supabase.client
            .from("subscriptions")
            .update(update)
            .eq("user_id", value: userId.uuidString)
            .execute()

        if update.status == .active {
            await trackSubscriptionStarted(
                userId: userId,
                planType: update.plan_type
            )
        } else {
            await trackSubscriptionCanceled(
                userId: userId,
                planType: update.plan_type
            )
        }
    }

    func syncSubscription() async throws {
        let userId = try await authProvider.requireCurrentUserID()
        try await syncSubscription(userId: userId)
    }

    func trackTrialStarted(
        userId: UUID,
        planType: SubscriptionPlanType = .fullAccess,
        date: Date = Date()
    ) async {
        await trackMonetizationEvent(
            .trialStarted,
            userId: userId,
            planType: planType,
            date: date
        )
    }

    func trackSubscriptionStarted(
        userId: UUID,
        planType: SubscriptionPlanType = .fullAccess,
        date: Date = Date()
    ) async {
        await trackMonetizationEvent(
            .subscriptionStarted,
            userId: userId,
            planType: planType,
            date: date
        )
    }

    func trackSubscriptionCanceled(
        userId: UUID,
        planType: SubscriptionPlanType = .maintenance,
        date: Date = Date()
    ) async {
        await trackMonetizationEvent(
            .subscriptionCanceled,
            userId: userId,
            planType: planType,
            date: date
        )
    }

    private func trackMonetizationEvent(
        _ eventName: AnalyticsService.EventName,
        userId: UUID,
        planType: SubscriptionPlanType,
        date: Date
    ) async {
        await analyticsService.trackEvent(
            eventName,
            properties: [
                "plan_type": planType.rawValue,
                "timestamp": Self.analyticsTimestamp(for: date)
            ]
        )
    }

    private static func analyticsTimestamp(for date: Date) -> String {
        AnalyticsTimestamp.string(for: date)
    }

}
