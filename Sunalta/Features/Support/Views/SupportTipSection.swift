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
        let selectedTipEmoji = switch selectedProduct?.id {
        case "sunalta_tip_generous": "🤑"
        case "sunalta_tip_extra": "😱"
        default: "❤️"
        }
        VStack(spacing: 24) {
            if tips.isLoadingProducts {
                ProgressView("Loading tips…")
                    .padding()
            } else if let error = tips.productLoadingError {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(theme.palette.secondaryForeground)
                Button("Try again") {
                    Task { await tips.loadProducts() }
                }
                .frame(minHeight: 44)
            } else if !tips.products.isEmpty {
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 0))
                layout {
                    ForEach(tips.products) { product in
                        SupportTipOption(product: product, isSelected: selectedProduct?.id == product.id) {
                            selectedProductID = product.id
                        }
                    }
                }
                .padding(3)
                .background(
                    theme.palette.foreground.opacity(theme.colorScheme == .dark ? 0.18 : 0.08),
                    in: .capsule
                )
                .disabled(tips.isPurchasing || tips.needsVerification)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Tip amount")
            }

            Button {
                guard let selectedProduct else { return }
                Task { await tips.tip(selectedProduct) { try await purchase(selectedProduct) } }
            } label: {
                HStack {
                    if tips.isPurchasing {
                        ProgressView()
                            .tint(theme.palette.onControl)
                            .accessibilityLabel("Completing tip…")
                    } else {
                        Text(selectedProduct.map { "Tip \($0.displayPrice) \(selectedTipEmoji)" } ?? "Leave a tip")
                            .font(.headline)
                            .foregroundStyle(theme.palette.onControl)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 40)
            }
            .frame(minHeight: 50)
            .buttonStyle(.glassProminent)
            .tint(theme.palette.control)
            .disabled(selectedProduct == nil || tips.isLoadingProducts || tips.isPurchasing || tips.needsVerification)

            if let error = tips.purchaseError {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(theme.palette.error)
                if tips.needsVerification {
                    Button("Check purchase status") {
                        Task { await tips.checkUnfinishedTransactions() }
                    }
                    .frame(minHeight: 44)
                }
            }
            if let message = tips.purchaseMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(theme.palette.secondaryForeground)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}
