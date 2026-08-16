import Foundation
import StoreKit
import SwiftUI

/// Manages StoreKit 2 In-App Purchases, Product Fetching, Purchases, and Restore Entitlements.
@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isPurchasing = false
    @Published var errorMessage: String?
    @Published var isAdsRemoved = false

    struct ProductIDs {
        static let stars60 = "com.snackswap.adventure.stars60"
        static let stars180 = "com.snackswap.adventure.stars180"
        static let stars500 = "com.snackswap.adventure.stars500"
        static let removeAds = "com.snackswap.adventure.removeads"

        static let all: Set<String> = [stars60, stars180, stars500, removeAds]
    }

    /// Single source of truth for the star bundles: the ID must match the
    /// product in App Store Connect, and `stars` is what the purchase grants.
    /// The shop UI is built from this, so a bundle can never advertise one
    /// amount and credit another.
    struct StarPack: Identifiable {
        let id: String
        let stars: Int
        let title: String
        let fallbackPrice: String
        let icon: String
    }

    static let starPacks: [StarPack] = [
        StarPack(id: ProductIDs.stars60, stars: 60, title: "60 Stars",
                 fallbackPrice: "$0.99", icon: "star.fill"),
        StarPack(id: ProductIDs.stars180, stars: 180, title: "180 Stars",
                 fallbackPrice: "$2.99", icon: "star.leadinghalf.filled"),
        StarPack(id: ProductIDs.stars500, stars: 500, title: "500 Stars",
                 fallbackPrice: "$6.99", icon: "crown.fill")
    ]

    static let adsRemovedKey = "ssa.isAdsRemoved"

    private var transactionTask: Task<Void, Error>?

    private init() {
        // Seed from disk so a paying player is not shown ads during the window
        // between launch and StoreKit returning current entitlements.
        isAdsRemoved = UserDefaults.standard.bool(forKey: Self.adsRemovedKey)
        transactionTask = listenForTransactions()
        Task {
            await fetchProducts()
            await updatePurchasedStatus()
        }
    }

    deinit {
        transactionTask?.cancel()
    }

    func loadProducts() async {
        await fetchProducts()
    }

    /// Fetch products using StoreKit 2
    func fetchProducts() async {
        do {
            let storeProducts = try await Product.products(for: ProductIDs.all)
            self.products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            print("[StoreManager] Failed product fetch: \(error.localizedDescription)")
        }
    }

    /// Purchase product
    func purchase(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                handleSuccessfulPurchase(transaction)
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Called when a buy button is tapped but StoreKit has no such product.
    /// Previously the shop silently granted the item for free here.
    func reportStoreUnavailable() {
        errorMessage = "The App Store is unavailable right now. Please try again in a moment."
        Task { await fetchProducts() }
    }

    /// Restore prior purchases
    func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await updatePurchasedStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Listen to background transactions (e.g. Family Sharing, external renewals)
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await MainActor.run {
                        self.handleSuccessfulPurchase(transaction)
                    }
                    await transaction.finish()
                } catch {
                    print("[StoreManager] Transaction verification failed: \(error)")
                }
            }
        }
    }

    /// Check entitlement status
    func updatePurchasedStatus() async {
        var purchased: Set<String> = []

        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("[StoreManager] Entitlement verification failed: \(error)")
            }
        }

        self.purchasedProductIDs = purchased
        self.isAdsRemoved = purchased.contains(ProductIDs.removeAds)
        UserDefaults.standard.set(isAdsRemoved, forKey: Self.adsRemovedKey)
    }

    private func handleSuccessfulPurchase(_ transaction: StoreKit.Transaction) {
        purchasedProductIDs.insert(transaction.productID)

        if let pack = Self.starPacks.first(where: { $0.id == transaction.productID }) {
            PlayerProfile.shared.addStars(pack.stars)
            return
        }

        if transaction.productID == ProductIDs.removeAds {
            isAdsRemoved = true
            UserDefaults.standard.set(true, forKey: Self.adsRemovedKey)
        }
    }

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
