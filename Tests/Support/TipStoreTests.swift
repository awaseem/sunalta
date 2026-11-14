import Testing

@testable import Sunalta

@MainActor
struct TipStoreTests {
    @Test func unavailableProductsNeverEnableAPurchase() async {
        let store = TipStore(fetchProducts: { [] })
        await store.loadProducts()
        #expect(store.products.isEmpty && store.productLoadingError != nil)
        #expect(!store.isLoadingProducts && store.completedTipCount == 0)
    }
}
