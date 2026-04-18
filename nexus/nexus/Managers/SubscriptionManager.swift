import Foundation
import Combine
import StoreKit

// MARK: - Subscription Manager (StoreKit 2)

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // Product IDs — зарегистрировать в App Store Connect
    static let monthlyID  = "com.nexus.pro.monthly"
    static let semiAnnualID = "com.nexus.pro.semiannual"
    static let lifetimeID = "com.nexus.pro.lifetime"

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var error: String?

    var isSubscribed: Bool {
        !purchasedProductIDs.isEmpty
    }

    var currentPlan: SubscriptionPlan {
        if purchasedProductIDs.isEmpty { return .free }
        if purchasedProductIDs.contains(Self.lifetimeID) { return .premium }
        return .pro
    }

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts(); await updatePurchasedProducts() }
    }

    deinit { transactionListener?.cancel() }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let ids: Set<String> = [Self.monthlyID, Self.semiAnnualID, Self.lifetimeID]
            products = try await Product.products(for: ids)
                .sorted { $0.price < $1.price }
        } catch {
            self.error = "Не удалось загрузить продукты: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePurchasedProducts()
                return true
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            self.error = "Ошибка покупки: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }

    // MARK: - Transaction Updates

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in StoreKit.Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                    await self.updatePurchasedProducts()
                }
            }
        }
    }

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        // Auto-renewable subscriptions
        for await result in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }

        purchasedProductIDs = purchased
    }

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let item): return item
        }
    }

    // MARK: - Helpers

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    var monthlyProduct: Product? { product(for: Self.monthlyID) }
    var semiAnnualProduct: Product? { product(for: Self.semiAnnualID) }
    var lifetimeProduct: Product? { product(for: Self.lifetimeID) }
}
