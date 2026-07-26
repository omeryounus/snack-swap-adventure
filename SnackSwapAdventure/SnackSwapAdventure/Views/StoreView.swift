import SwiftUI
import StoreKit

/// Store UI presenting Star Bundles, Remove Ads Pass, and Restore Purchases.
struct StoreView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeManager = StoreManager.shared
    @StateObject private var profile = PlayerProfile.shared

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [Color(hex: "2A1B4E"), Color(hex: "170D38"), Color(hex: "0D0622")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Spacer()

                    Text("SNACK SHOP 🛍️")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Spacer()

                    // Star Counter
                    HStack(spacing: 4) {
                        Text("⭐")
                            .font(.system(size: 16))
                        Text("\(profile.stars)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.yellow)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Remove Ads Banner Card
                        removeAdsCard

                        // Star Packs Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("STAR PACKS ⭐")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal, 4)

                            starPackRow(
                                title: "Handful of Stars",
                                stars: 500,
                                icon: "✨",
                                defaultPrice: "$0.99",
                                productID: StoreManager.ProductIDs.stars500
                            )

                            starPackRow(
                                title: "Pouch of Stars",
                                stars: 1500,
                                icon: "🌟",
                                defaultPrice: "$2.99",
                                productID: StoreManager.ProductIDs.stars1500,
                                badge: "POPULAR 🔥"
                            )

                            starPackRow(
                                title: "Vault of Stars",
                                stars: 5000,
                                icon: "👑",
                                defaultPrice: "$7.99",
                                productID: StoreManager.ProductIDs.stars5000,
                                badge: "BEST VALUE 💎"
                            )
                        }

                        // Restore Purchases Button
                        Button(action: {
                            Task {
                                await storeManager.restorePurchases()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                Text("Restore Purchases")
                            }
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.vertical, 12)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
    }

    // MARK: - Remove Ads Card
    private var removeAdsCard: some View {
        HStack(spacing: 16) {
            Text("🚫")
                .font(.system(size: 40))
                .padding(12)
                .background(Color.red.opacity(0.2))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("REMOVE ADS")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    if storeManager.isAdsRemoved {
                        Text("PURCHASED ✅")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                Text("Enjoy uninterrupted snack swapping with 0 ad popups!")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if !storeManager.isAdsRemoved {
                Button(action: {
                    if let product = storeManager.products.first(where: { $0.id == StoreManager.ProductIDs.removeAds }) {
                        Task { await storeManager.purchase(product) }
                    } else {
                        // Fallback simulated unlock
                        storeManager.isAdsRemoved = true
                        UserDefaults.standard.set(true, forKey: "ssa.isAdsRemoved")
                    }
                }) {
                    Text(productPrice(for: StoreManager.ProductIDs.removeAds, defaultPrice: "$1.99"))
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .purple.opacity(0.4), radius: 6, y: 3)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(LinearGradient(colors: [.pink.opacity(0.5), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                )
        )
    }

    // MARK: - Star Pack Row
    private func starPackRow(
        title: String,
        stars: Int,
        icon: String,
        defaultPrice: String,
        productID: String,
        badge: String? = nil
    ) -> some View {
        HStack(spacing: 14) {
            Text(icon)
                .font(.system(size: 34))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow)
                            .clipShape(Capsule())
                    }
                }

                Text("⭐ +\(stars) Stars")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.yellow)
            }

            Spacer()

            Button(action: {
                if let product = storeManager.products.first(where: { $0.id == productID }) {
                    Task { await storeManager.purchase(product) }
                } else {
                    // Fallback simulated purchase
                    profile.addStars(stars)
                }
            }) {
                Text(productPrice(for: productID, defaultPrice: defaultPrice))
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .orange.opacity(0.4), radius: 4, y: 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func productPrice(for productID: String, defaultPrice: String) -> String {
        if let product = storeManager.products.first(where: { $0.id == productID }) {
            return product.displayPrice
        }
        return defaultPrice
    }
}
