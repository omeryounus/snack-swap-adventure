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
        static let stars500 = "com.snackswap.adventure.stars.500"
        static let stars1500 = "com.snackswap.adventure.stars.1500"
        static let stars5000 = "com.snackswap.adventure.stars.5000"
        static let removeAds = "com.snackswap.adventure.removeads"

        static let all: Set<String> = [stars500, stars1500, stars5000, removeAds]
    }

    private var transactionTask: Task<Void, Error>?

    private init() {
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
        UserDefaults.standard.set(isAdsRemoved, forKey: "ssa.isAdsRemoved")
    }

    private func handleSuccessfulPurchase(_ transaction: StoreKit.Transaction) {
        purchasedProductIDs.insert(transaction.productID)

        switch transaction.productID {
        case ProductIDs.stars500:
            PlayerProfile.shared.addStars(500)
        case ProductIDs.stars1500:
            PlayerProfile.shared.addStars(1500)
        case ProductIDs.stars5000:
            PlayerProfile.shared.addStars(5000)
        case ProductIDs.removeAds:
            isAdsRemoved = true
            UserDefaults.standard.set(true, forKey: "ssa.isAdsRemoved")
        default:
            break
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
