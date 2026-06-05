import StoreKit
import SwiftUI

struct SubscriptionManagementView: View {

    private enum LoadState {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private let subscriptionService: SubscriptionService
    private let userId: UUID?

    @State private var products: [Product] = []
    @State private var entitlement: SubscriptionEntitlement?
    @State private var loadState: LoadState = .idle
    @State private var isSyncing = false
    @State private var syncMessage: String?

    init(
        subscriptionService: SubscriptionService = SubscriptionService(),
        userId: UUID? = nil
    ) {
        self.subscriptionService = subscriptionService
        self.userId = userId
    }

    var body: some View {

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                statusCard
                productSection
                actionSection
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadSubscription()
        }

    }

    private var header: some View {

        VStack(alignment: .leading, spacing: 8) {
            Text("SUBSCRIPTION")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(Color.secondary)

            Text("Manage access to the full RNF experience.")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)

    }

    private var statusCard: some View {

        HStack(alignment: .center, spacing: 14) {
            Image(systemName: entitlement == nil ? "lock.open.fill" : "checkmark.seal.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(statusTint)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(statusTint.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(entitlement == nil ? "Maintenance Access" : "Full Access Active")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)

                Text(statusDetail)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)
        }
        .padding(16)
        .subscriptionCardBackground()

    }

    @ViewBuilder
    private var productSection: some View {

        VStack(alignment: .leading, spacing: 12) {
            Text("Plans")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)

            switch loadState {
            case .idle, .loading:
                ProgressView("Loading plans")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 92)
                    .subscriptionCardBackground()
            case .loaded where products.isEmpty:
                emptyProductsView
            case .loaded:
                VStack(spacing: 12) {
                    ForEach(products, id: \.id) { product in
                        productRow(product)
                    }
                }
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
                    .padding(16)
                    .subscriptionCardBackground()
            }
        }

    }

    private var emptyProductsView: some View {

        VStack(alignment: .leading, spacing: 8) {
            Text("No plans configured")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)

            Text("StoreKit product identifiers can be supplied when this screen is wired into the app shell.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding(16)
        .subscriptionCardBackground()

    }

    private func productRow(_ product: Product) -> some View {

        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(product.displayName)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(product.description)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(2)

                Text(product.displayPrice)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(Color.accentColor)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.secondary)
        }
        .padding(16)
        .subscriptionCardBackground()

    }

    private var actionSection: some View {

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    Task {
                        await loadSubscription()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isBusy)

                if userId != nil {
                    Button {
                        Task {
                            await syncSubscription()
                        }
                    } label: {
                        Label(isSyncing ? "Syncing" : "Sync", systemImage: "icloud.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isBusy)
                }
            }

            if let syncMessage {
                Text(syncMessage)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

    }

    private var isBusy: Bool {
        if case .loading = loadState {
            return true
        }

        return isSyncing
    }

    private var statusTint: Color {
        entitlement == nil ? Color(red: 0.3, green: 0.43, blue: 0.86) : Color(red: 0.12, green: 0.54, blue: 0.3)
    }

    private var statusDetail: String {
        guard let entitlement else {
            return "Subscribe to unlock full access when plans are available."
        }

        guard let expirationDate = entitlement.expirationDate else {
            return "Your full access entitlement is active."
        }

        return "Renews \(expirationDate.formatted(date: .abbreviated, time: .omitted))."
    }

    private func loadSubscription() async {
        loadState = .loading
        syncMessage = nil

        do {
            async let fetchedProducts = subscriptionService.fetchProducts()
            async let activeEntitlement = subscriptionService.validateEntitlement()

            products = try await fetchedProducts
            entitlement = await activeEntitlement
            loadState = .loaded
        } catch is CancellationError {
            return
        } catch {
            products = []
            entitlement = nil
            loadState = .failed("Plans could not be loaded")
        }
    }

    private func syncSubscription() async {
        guard userId != nil else { return }

        isSyncing = true
        syncMessage = nil

        do {
            try await subscriptionService.syncSubscription()
            entitlement = await subscriptionService.validateEntitlement()
            syncMessage = "Subscription state synced."
        } catch {
            syncMessage = "Subscription state could not be synced."
        }

        isSyncing = false
    }

}

private extension View {

    func subscriptionCardBackground() -> some View {
        background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
        )
    }

}

#Preview {
    NavigationStack {
        SubscriptionManagementView()
    }
}
