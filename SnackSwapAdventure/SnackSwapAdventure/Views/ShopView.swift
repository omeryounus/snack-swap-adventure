import SwiftUI
import StoreKit

/// Screen 10: Shop — StoreKit 2 Star bundles, booster packs, remove ads & restore purchases.
struct ShopView: View {
    let onBack: () -> Void

    @StateObject private var storeManager = StoreManager.shared
    @StateObject private var profile = PlayerProfile.shared

    @Environment(\.adaptiveLayout) private var layout

    var body: some View {
        ScreenScaffold(
            title: "SHOP",
            subtitle: "\(profile.stars) ⭐ Balance",
            accent: SSATheme.candyYellow,
            themeColor: SSATheme.candyGreen,
            onBack: onBack
        ) {
                    VStack(spacing: 20) {
                        // Remove Ads Banner
                        SSAGlassCard(padding: 16) {
                            HStack(spacing: 14) {
                                Text("🚫")
                                    .font(.system(size: layout.isCompactWidth ? 32 : 44))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("REMOVE ADS")
                                        .font(.caption.bold())
                                        .foregroundStyle(SSATheme.candyPink)

                                    Text("Ad-Free Experience")
                                        .font(.title3.bold())
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)

                                    Text(storeManager.isAdsRemoved ? "Purchased ✅" : "No Interstitial Ads!")
                                        .font(.caption)
                                        .foregroundStyle(storeManager.isAdsRemoved ? .green : SSATheme.textSecondary)
                                }

                                Spacer(minLength: 4)

                                if !storeManager.isAdsRemoved {
                                    Button {
                                        SoundManager.shared.playUITap()
                                        // Entitlements come from StoreKit only — never
                                        // granted locally when the product fails to load.
                                        if let product = storeManager.products.first(where: { $0.id == StoreManager.ProductIDs.removeAds }) {
                                            Task { await storeManager.purchase(product) }
                                        } else {
                                            storeManager.reportStoreUnavailable()
                                        }
                                    } label: {
                                        Text(productPrice(for: StoreManager.ProductIDs.removeAds, fallback: "$1.99"))
                                            .font(.headline.bold())
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(SSATheme.primaryGradient)
                                            .foregroundStyle(.white)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // Star Packs Section
                        Text("Star Bundles")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVGrid(columns: layout.gridItems(count: layout.shopGridColumns), spacing: 14) {
                            ForEach(StoreManager.starPacks) { pack in
                                ShopItemCard(
                                    title: pack.title,
                                    price: productPrice(for: pack.id, fallback: pack.fallbackPrice),
                                    icon: pack.icon,
                                    amount: pack.stars
                                ) {
                                    // Stars are credited by handleSuccessfulPurchase
                                    // once StoreKit verifies the transaction.
                                    if let product = storeManager.products.first(where: { $0.id == pack.id }) {
                                        Task { await storeManager.purchase(product) }
                                    } else {
                                        storeManager.reportStoreUnavailable()
                                    }
                                }
                            }
                        }

                        // Booster Packs Section
                        Text("Booster Refills")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 12) {
                            BoosterShopRow(title: "3x Snack Hammer", price: "30 ⭐", icon: "hammer.fill") {
                                if profile.stars >= 30 {
                                    profile.deductStars(30)
                                    profile.hammerCount += 3
                                }
                            }
                            BoosterShopRow(title: "3x Color Bomb", price: "50 ⭐", icon: "atom") {
                                if profile.stars >= 50 {
                                    profile.deductStars(50)
                                    profile.colorBombCount += 3
                                }
                            }
                            BoosterShopRow(title: "3x Extra Moves", price: "40 ⭐", icon: "plus.circle.fill") {
                                if profile.stars >= 40 {
                                    profile.deductStars(40)
                                    profile.extraMovesCount += 3
                                }
                            }
                        }

                        // Restore Purchases
                        Button {
                            SoundManager.shared.playUITap()
                            Task { await storeManager.restorePurchases() }
                        } label: {
                            Text("Restore Purchases")
                                .font(.caption.bold())
                                .foregroundStyle(SSATheme.textSecondary)
                                .padding(.top, 10)
                        }
                    }
        }
        // Purchase failures used to be written to errorMessage and never shown.
        .alert(
            "Purchase Unavailable",
            isPresented: Binding(
                get: { storeManager.errorMessage != nil },
                set: { if !$0 { storeManager.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { storeManager.errorMessage = nil }
        } message: {
            Text(storeManager.errorMessage ?? "")
        }
    }

    private func productPrice(for id: String, fallback: String) -> String {
        if let p = storeManager.products.first(where: { $0.id == id }) {
            return p.displayPrice
        }
        return fallback
    }
}

private struct ShopItemCard: View {
    let title: String
    let price: String
    let icon: String
    let amount: Int
    let onBuy: () -> Void

    var body: some View {
        SSAGlassCard(padding: 14) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(SSATheme.candyYellow)

                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Button {
                    SoundManager.shared.playUITap()
                    onBuy()
                } label: {
                    Text(price)
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(SSATheme.primaryGradient)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

private struct BoosterShopRow: View {
    let title: String
    let price: String
    let icon: String
    let onBuy: () -> Void

    var body: some View {
        SSAGlassCard(padding: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(SSATheme.candyCyan)

                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    SoundManager.shared.playUITap()
                    onBuy()
                } label: {
                    Text(price)
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .foregroundStyle(SSATheme.candyYellow)
                        .clipShape(Capsule())
                }
            }
        }
    }
}
