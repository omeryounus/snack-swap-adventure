import Foundation
import StoreKit

/// StoreKit 2 manager for star packs.
@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    enum ProductID {
        static let stars60 = "com.snackswap.adventure.stars60"
        static let stars180 = "com.snackswap.adventure.stars180"
        static let stars500 = "com.snackswap.adventure.stars500"

        static let all: [String] = [stars60, stars180, stars500]

        static func starAmount(for productId: String) -> Int {
            switch productId {
            case stars60: return 60
            case stars180: return 180
            case stars500: return 500
            default: return 0
            }
        }
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?
    @Published private(set) var purchaseInFlight: String?

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = Task { await listenForTransactions() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        do {
            let storeProducts = try await Product.products(for: ProductID.all)
            products = storeProducts.sorted { $0.price < $1.price }
            if products.isEmpty {
                lastError = "No products found. Use the included StoreKit config in Xcode scheme."
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async -> Bool {
        purchaseInFlight = product.id
        lastError = nil
        defer { purchaseInFlight = nil }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                grantStars(for: product.id)
                await transaction.finish()
                return true
            case .userCancelled:
                return false
            case .pending:
                lastError = "Purchase pending approval."
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// Debug/local fallback when StoreKit products aren't configured yet.
    func grantDebugStars(_ amount: Int) {
        #if DEBUG
        MetaProgress.shared.addStars(amount)
        #endif
    }

    private func grantStars(for productId: String) {
        let amount = ProductID.starAmount(for: productId)
        guard amount > 0 else { return }
        MetaProgress.shared.addStars(amount)
        SoundManager.shared.playExtend()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    private func listenForTransactions() async {
        for await update in Transaction.updates {
            do {
                let transaction = try checkVerified(update)
                grantStars(for: transaction.productID)
                await transaction.finish()
            } catch {
                // Ignore failed verification in listener.
            }
        }
    }
}
