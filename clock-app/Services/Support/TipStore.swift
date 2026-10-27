import Observation
import StoreKit

/// Owns the optional tip flow independently of the sheet, including delayed approvals.
@MainActor
@Observable
final class TipStore {
    // Create these consumable products in Clock App's App Store Connect record before release.
    static let productIDs = ["clock_app_tip_small", "clock_app_tip_generous", "clock_app_tip_extra"]

    private(set) var products: [Product] = []
    private(set) var isLoadingProducts = false
    private(set) var isPurchasing = false
    private(set) var productLoadingError: String?
    private(set) var purchaseError: String?
    private(set) var purchaseMessage: String?
    private(set) var needsVerification = false
    private(set) var completedTipCount = 0

    @ObservationIgnored private var completedTransactionIDs: Set<UInt64> = []
    @ObservationIgnored private var unverifiedTransactionIDs: Set<UInt64> = []
    @ObservationIgnored private var isObserving = false
    @ObservationIgnored private let fetchProducts: () async throws -> [Product]

    init(fetchProducts: @escaping () async throws -> [Product] = {
        try await Product.products(for: TipStore.productIDs)
    }) {
        self.fetchProducts = fetchProducts
    }

    func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        productLoadingError = nil
        defer { isLoadingProducts = false }

        do {
            products = try await fetchProducts()
                .filter { Self.productIDs.contains($0.id) && $0.type == .consumable }
                .sorted { $0.price < $1.price }
            if products.isEmpty {
                productLoadingError = "Tips are unavailable right now. Please try again later."
            }
        } catch is CancellationError {
            return
        } catch {
            products = []
            productLoadingError = "Couldn't load tips. Please check your connection and try again."
        }
    }

    /// The view supplies its scene's native SwiftUI purchase action.
    func tip(_ product: Product, purchase: () async throws -> Product.PurchaseResult) async {
        guard !isPurchasing, !isLoadingProducts, !needsVerification,
              products.contains(where: { $0.id == product.id }) else { return }
        isPurchasing = true
        purchaseError = nil
        purchaseMessage = nil
        defer { isPurchasing = false }

        do {
            switch try await purchase() {
            case .success(let result):
                await handleTransaction(result)
            case .userCancelled:
                purchaseMessage = "Tip cancelled. You can keep enjoying Clock App."
            case .pending:
                purchaseMessage = "Your tip is awaiting approval. You can close this page and keep using Clock App."
            @unknown default:
                purchaseError = "Couldn't complete your tip. Please try again."
            }
        } catch StoreKitError.userCancelled {
            purchaseMessage = "Tip cancelled. You can keep enjoying Clock App."
        } catch is CancellationError {
            return
        } catch {
            purchaseError = "Couldn't complete your tip. Please check your connection and try again."
        }
    }

    func observeTransactions() async {
        guard !isObserving else { return }
        isObserving = true
        defer { isObserving = false }
        // StoreKit also delivers unfinished transactions when the listener starts at launch.
        for await result in Transaction.updates {
            guard !Task.isCancelled else { return }
            await handleTransaction(result)
        }
    }

    func checkUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            guard !Task.isCancelled else { return }
            await handleTransaction(result)
        }
    }

    func handleTransaction(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            guard Self.productIDs.contains(transaction.productID), transaction.productType == .consumable else { return }
            unverifiedTransactionIDs.remove(transaction.id)
            needsVerification = !unverifiedTransactionIDs.isEmpty
            if !needsVerification { purchaseError = nil }
            guard transaction.revocationDate == nil else {
                await transaction.finish()
                return
            }
            let isNewTip = completedTransactionIDs.insert(transaction.id).inserted
            await transaction.finish()
            guard isNewTip else { return }
            purchaseMessage = nil
            completedTipCount += 1
        case .unverified(let transaction, _):
            guard Self.productIDs.contains(transaction.productID) else { return }
            unverifiedTransactionIDs.insert(transaction.id)
            needsVerification = true
            purchaseError = "Your purchase couldn't be verified yet. Check its status before trying another tip."
        }
    }
}
