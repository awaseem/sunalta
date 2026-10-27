import StoreKit
import SwiftUI

struct SupportTipSection: View {
    @Environment(TipStore.self) private var tips
    @Environment(\.appTheme) private var theme
    @Environment(\.purchase) private var purchase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedProductID: String?

    var body: some View {
        let selectedProduct = tips.products.first { $0.id == selectedProductID } ?? tips.products.first
        VStack {
            if tips.isLoadingProducts {
                ProgressView("Loading tips…")
                    .padding()
            } else if let error = tips.productLoadingError {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(theme.palette.secondaryForeground)
                Button("Try again") {
                    Task { await tips.loadProducts() }
                }
                .frame(minHeight: 44)
            } else if !tips.products.isEmpty {
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout()) : AnyLayout(HStackLayout())
                layout {
                    ForEach(tips.products) { product in
                        SupportTipOption(product: product, isSelected: selectedProduct?.id == product.id) {
                            selectedProductID = product.id
                        }
                    }
                }
                .disabled(tips.isPurchasing || tips.needsVerification)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Tip amount")

                Button {
                    guard let selectedProduct else { return }
                    Task { await tips.tip(selectedProduct) { try await purchase(selectedProduct) } }
                } label: {
                    if tips.isPurchasing {
                        Label("Completing tip…", systemImage: "hourglass")
                    } else {
                        Text(selectedProduct.map { "Tip \($0.displayPrice) ♥" } ?? "Leave a tip")
                    }
                }
                .buttonStyle(.appCapsule(fillsWidth: true))
                .disabled(selectedProduct == nil || tips.isPurchasing || tips.needsVerification)
                .padding(.top)

            }

            if let error = tips.purchaseError {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(theme.palette.error)
                    .padding(.top)
                if tips.needsVerification {
                    Button("Check purchase status") {
                        Task { await tips.checkUnfinishedTransactions() }
                    }
                    .frame(minHeight: 44)
                }
            }
            if let message = tips.purchaseMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(theme.palette.secondaryForeground)
                    .padding(.top)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}
