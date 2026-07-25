import SwiftUI

/// Screen 10: Shop — Coin/Star bundles, booster packs, remove ads & restore purchases.
struct ShopView: View {
    let onBack: () -> Void

    @StateObject private var meta = MetaProgress.shared

    var body: some View {
        ZStack(alignment: .top) {
            WorldBackgroundPlate(themeColor: SSATheme.candyGreen)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        SoundManager.shared.playUITap()
                        onBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("SHOP")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("\(meta.stars) ⭐ Balance")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(SSATheme.candyYellow)
                    }

                    Spacer()

                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Special Offer Card
                        SSAGlassCard(padding: 16) {
                            HStack(spacing: 14) {
                                Text("🎁")
                                    .font(.system(size: 44))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("STARTER BUNDLE")
                                        .font(.caption.bold())
                                        .foregroundStyle(SSATheme.candyYellow)

                                    Text("500 ⭐ + All Boosters")
                                        .font(.title3.bold())
                                        .foregroundStyle(.white)

                                    Text("Save 60% Today!")
                                        .font(.caption)
                                        .foregroundStyle(SSATheme.candyGreen)
                                }

                                Spacer()

                                Button {
                                    SoundManager.shared.playUITap()
                                    meta.addStars(500)
                                } label: {
                                    Text("$1.99")
                                        .font(.headline.bold())
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(SSATheme.primaryGradient)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        // Star Packs
                        Text("Star Bundles")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ShopItemCard(title: "100 Stars", price: "$0.99", icon: "star.fill", amount: 100) {
                                meta.addStars(100)
                            }
                            ShopItemCard(title: "300 Stars", price: "$2.99", icon: "star.fill", amount: 300) {
                                meta.addStars(300)
                            }
                            ShopItemCard(title: "750 Stars", price: "$5.99", icon: "star.fill", amount: 750) {
                                meta.addStars(750)
                            }
                            ShopItemCard(title: "2000 Stars", price: "$12.99", icon: "star.fill", amount: 2000) {
                                meta.addStars(2000)
                            }
                        }

                        // Booster Packs
                        Text("Booster Packs")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 12) {
                            BoosterShopRow(title: "5x Extra Moves (+5)", price: "50 ⭐", icon: "hand.tap.fill") {
                                if meta.stars >= 50 {
                                    _ = meta.spendStars(50)
                                    meta.queueBooster("moves")
                                }
                            }
                            BoosterShopRow(title: "5x Extra Time (+30s)", price: "50 ⭐", icon: "clock.fill") {
                                if meta.stars >= 50 {
                                    _ = meta.spendStars(50)
                                    meta.queueBooster("time")
                                }
                            }
                            BoosterShopRow(title: "3x Snack Hammer", price: "80 ⭐", icon: "hammer.fill") {
                                if meta.stars >= 80 {
                                    _ = meta.spendStars(80)
                                    meta.queueBooster("hammer")
                                }
                            }
                        }

                        // Restore Purchases
                        Button {
                            SoundManager.shared.playUITap()
                            Task { await StoreManager.shared.restorePurchases() }
                        } label: {
                            Text("Restore Purchases")
                                .font(.caption.bold())
                                .foregroundStyle(SSATheme.textSecondary)
                                .padding(.top, 10)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
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
