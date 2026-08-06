import SwiftUI

/// P24-RET-15: Forge Token Shop with cosmetic items (profile borders, streak colors, card backgrounds).
/// Uses NavigationStack list pattern with categorized sections.
struct ForgeTokenShopView: View {

    @EnvironmentObject private var gameState: GameState
    @StateObject private var tokenService = ForgeTokenService()

    @State private var selectedCategory: CosmeticCategory = .borders
    @State private var purchaseConfirmation: ShopItem?
    @State private var showingPurchaseAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tokenBalanceHeader

                categoryPicker

                shopList
            }
            .navigationTitle("Forge Shop")
            .navigationBarTitleDisplayMode(.large)
            .alert("Unlock Item", isPresented: $showingPurchaseAlert, presenting: purchaseConfirmation) { item in
                Button("Unlock for \(item.price) 🔥") {
                    purchaseItem(item)
                }
                Button("Cancel", role: .cancel) {}
            } message: { item in
                Text("Spend \(item.price) Forge Tokens to unlock \"\(item.name)\"?")
            }
        }
    }

    // MARK: - Token Balance Header

    private var tokenBalanceHeader: some View {
        HStack(spacing: RNFSpacing.sm) {
            Image(systemName: "flame.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(RNFColors.warning)

            Text("\(tokenBalance)")
                .font(RNFFont.cardTitle)
                .foregroundStyle(RNFColors.textPrimary)

            Text("Forge Tokens")
                .font(RNFFont.caption)
                .foregroundStyle(RNFColors.textSecondary)

            Spacer()
        }
        .padding(.horizontal, RNFSpacing.md)
        .padding(.vertical, RNFSpacing.sm)
        .background(RNFColors.surface)
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        Picker("Category", selection: $selectedCategory) {
            ForEach(CosmeticCategory.allCases) { category in
                Text(category.displayName).tag(category)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, RNFSpacing.md)
        .padding(.vertical, RNFSpacing.sm)
    }

    // MARK: - Shop List

    private var shopList: some View {
        List {
            ForEach(items(for: selectedCategory)) { item in
                ShopItemRow(item: item) {
                    purchaseConfirmation = item
                    showingPurchaseAlert = true
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Data

    private var tokenBalance: Int {
        tokenService.balance
    }

    private func items(for category: CosmeticCategory) -> [ShopItem] {
        ShopItem.catalog.filter { $0.category == category }
    }

    private func purchaseItem(_ item: ShopItem) {
        let success = tokenService.spend(amount: item.price, reason: "Purchased \(item.name)")
        if success {
            RNFHaptics.success()
        }
    }
}

// MARK: - Shop Item Row

private struct ShopItemRow: View {
    let item: ShopItem
    let onPurchase: () -> Void

    var body: some View {
        HStack(spacing: RNFSpacing.md) {
            // Preview swatch
            RoundedRectangle(cornerRadius: RNFRadius.sm, style: .continuous)
                .fill(item.previewColor)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: item.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(RNFFont.bodyBold)
                    .foregroundStyle(RNFColors.textPrimary)

                Text(item.description)
                    .font(RNFFont.captionSmall)
                    .foregroundStyle(RNFColors.textSecondary)
            }

            Spacer()

            Button(action: onPurchase) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                    Text("\(item.price)")
                        .font(RNFFont.captionBold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(RNFColors.primary)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, RNFSpacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(item.price) tokens")
        .accessibilityHint("Double tap to purchase")
    }
}

// MARK: - Models

enum CosmeticCategory: String, CaseIterable, Identifiable {
    case borders
    case streakColors
    case cardBackgrounds

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .borders: return "Borders"
        case .streakColors: return "Streaks"
        case .cardBackgrounds: return "Cards"
        }
    }
}

struct ShopItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let category: CosmeticCategory
    let price: Int
    let iconName: String
    let previewColor: Color

    static let catalog: [ShopItem] = [
        // Borders
        ShopItem(name: "Golden Forge", description: "Gilded profile border", category: .borders, price: 150, iconName: "circle.dashed", previewColor: Color(red: 0.85, green: 0.65, blue: 0.13)),
        ShopItem(name: "Shadow Edge", description: "Dark obsidian border", category: .borders, price: 120, iconName: "circle.dashed", previewColor: Color(red: 0.2, green: 0.2, blue: 0.25)),
        ShopItem(name: "Ember Ring", description: "Glowing ember border", category: .borders, price: 200, iconName: "circle.dashed", previewColor: Color(red: 0.9, green: 0.3, blue: 0.1)),

        // Streak Colors
        ShopItem(name: "Ice Blue", description: "Cool streak flame color", category: .streakColors, price: 80, iconName: "flame.fill", previewColor: Color(red: 0.4, green: 0.7, blue: 1.0)),
        ShopItem(name: "Emerald", description: "Rare green flame", category: .streakColors, price: 100, iconName: "flame.fill", previewColor: Color(red: 0.2, green: 0.8, blue: 0.4)),
        ShopItem(name: "Royal Purple", description: "Majestic purple flame", category: .streakColors, price: 120, iconName: "flame.fill", previewColor: RNFColors.primary),

        // Card Backgrounds
        ShopItem(name: "Starfield", description: "Deep space card background", category: .cardBackgrounds, price: 180, iconName: "sparkles", previewColor: Color(red: 0.1, green: 0.1, blue: 0.3)),
        ShopItem(name: "Forest", description: "Ancient woodland texture", category: .cardBackgrounds, price: 150, iconName: "leaf.fill", previewColor: Color(red: 0.15, green: 0.4, blue: 0.2)),
        ShopItem(name: "Volcanic", description: "Molten lava pattern", category: .cardBackgrounds, price: 200, iconName: "mountain.2.fill", previewColor: Color(red: 0.5, green: 0.1, blue: 0.05)),
    ]
}

// MARK: - Preview

#Preview {
    ForgeTokenShopView()
        .environmentObject(GameState())
}
