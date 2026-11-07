import Foundation
import StoreKit
import StoreKitTest
import Testing
@testable import Sunalta

@Suite(.serialized)
@MainActor
struct TipStoreTests {
    private func makeSession() async throws -> SKTestSession {
        let session = try SKTestSession(configurationFileNamed: "SupportTips")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        // The local StoreKit daemon can take a moment to activate a new configuration.
        let deadline = ContinuousClock.now.advanced(by: .seconds(5))
        while try await Product.products(for: TipStore.productIDs).count != TipStore.productIDs.count {
            try #require(ContinuousClock.now < deadline, "Local StoreKit products did not become available")
            try await Task.sleep(for: .milliseconds(50))
        }
        return session
    }

    @Test func verifiedPurchaseIsFinishedAndDuplicateDeliveryDoesNotThankTwice() async throws {
        let session = try await makeSession()
        defer { session.resetToDefaultState() }
        let store = TipStore()
        await store.loadProducts()
        let product = try #require(store.products.first)
        var result: Product.PurchaseResult?
        await store.tip(product) {
            let purchase = try await product.purchase()
            result = purchase
            return purchase
        }
        #expect(store.completedTipCount == 1)
        #expect(!store.isPurchasing && store.purchaseError == nil)
        guard case .success(let verification) = result else {
            Issue.record("Expected a successful StoreKit test purchase")
            return
        }
        await store.handleTransaction(verification)
        #expect(store.completedTipCount == 1)
        for await unfinished in Transaction.unfinished {
            #expect(unfinished.unsafePayloadValue.productID != product.id)
        }
    }

    @Test(arguments: [false, true])
    func cancelledPurchaseDoesNotShowThanksOrAnError(throwsCancellation: Bool) async throws {
        let session = try await makeSession()
        defer { session.resetToDefaultState() }
        let store = TipStore()
        await store.loadProducts()
        let product = try #require(store.products.first)
        await store.tip(product) {
            if throwsCancellation { throw StoreKitError.userCancelled }
            return .userCancelled
        }
        #expect(store.completedTipCount == 0 && store.purchaseError == nil)
        #expect(store.purchaseMessage != nil && !store.isPurchasing)
    }

    @Test func pendingPurchaseThanksOnlyAfterApprovalThroughTheListener() async throws {
        let session = try await makeSession()
        defer { session.resetToDefaultState() }
        session.askToBuyEnabled = true
        let store = TipStore()
        let listener = Task { await store.observeTransactions() }
        defer { listener.cancel() }
        await store.loadProducts()
        let product = try #require(store.products.first)
        await store.tip(product) { try await product.purchase() }
        #expect(store.completedTipCount == 0 && store.purchaseMessage != nil)
        let pending = try #require(session.allTransactions().first)
        try session.approveAskToBuyTransaction(identifier: pending.identifier)
        let deadline = ContinuousClock.now.advanced(by: .seconds(5))
        while store.completedTipCount == 0, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(store.completedTipCount == 1)
        #expect(store.purchaseMessage == nil && store.purchaseError == nil)
    }

    @Test func failedPurchaseCanBeRetriedWithoutFalseSuccess() async throws {
        let session = try await makeSession()
        defer { session.resetToDefaultState() }
        let store = TipStore()
        await store.loadProducts()
        let product = try #require(store.products.first)
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .purchase)
        await store.tip(product) { try await product.purchase() }
        #expect(store.completedTipCount == 0 && store.purchaseError != nil)
        #expect(!store.isPurchasing)
        try await session.setSimulatedError(nil, forAPI: .purchase)
        await store.tip(product) { try await product.purchase() }
        #expect(store.completedTipCount == 1 && store.purchaseError == nil)
    }

    @Test func repeatedTapDoesNotStartASecondPurchaseWhileConfirmationIsOpen() async throws {
        let session = try await makeSession()
        defer { session.resetToDefaultState() }
        let store = TipStore()
        await store.loadProducts()
        let product = try #require(store.products.first)
        var continuation: CheckedContinuation<Product.PurchaseResult, Never>?
        let first = Task {
            await store.tip(product) {
                await withCheckedContinuation { continuation = $0 }
            }
        }
        while continuation == nil { await Task.yield() }
        var duplicateStarted = false
        await store.tip(product) {
            duplicateStarted = true
            return .userCancelled
        }
        #expect(!duplicateStarted && store.isPurchasing)
        continuation?.resume(returning: .userCancelled)
        await first.value
        #expect(!store.isPurchasing && store.completedTipCount == 0)
    }

    @Test func unverifiedPurchaseBlocksAnotherChargeUntilVerificationSucceeds() async throws {
        let session = try await makeSession()
        defer { session.resetToDefaultState() }
        let store = TipStore()
        await store.loadProducts()
        let product = try #require(store.products.first)
        let transaction = try await session.buyProduct(identifier: product.id)
        await store.handleTransaction(.unverified(transaction, .invalidSignature))
        #expect(store.completedTipCount == 0 && store.needsVerification)
        var purchasedAgain = false
        await store.tip(product) {
            purchasedAgain = true
            return .userCancelled
        }
        #expect(!purchasedAgain)
        await store.handleTransaction(.verified(transaction))
        #expect(store.completedTipCount == 1 && !store.needsVerification)
        #expect(store.purchaseError == nil)
    }

    @Test func productLoadFailureClearsStalePricesAndAllowsRetry() async throws {
        let session = try await makeSession()
        defer { session.resetToDefaultState() }
        let store = TipStore()
        await store.loadProducts()
        try #require(!store.products.isEmpty)
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .loadProducts)
        await store.loadProducts()
        #expect(store.products.isEmpty && store.productLoadingError != nil)
        try await session.setSimulatedError(nil, forAPI: .loadProducts)
        await store.loadProducts()
        #expect(!store.products.isEmpty && store.productLoadingError == nil)
    }

    @Test func unavailableProductsNeverEnableAPurchase() async {
        let store = TipStore(fetchProducts: { [] })
        await store.loadProducts()
        #expect(store.products.isEmpty && store.productLoadingError != nil)
        #expect(!store.isLoadingProducts && store.completedTipCount == 0)
    }
}
