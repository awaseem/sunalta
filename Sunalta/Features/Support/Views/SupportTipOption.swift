import StoreKit
import SwiftUI

struct SupportTipOption: View {
    @Environment(\.appTheme) private var theme
    let product: Product
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            Text(product.displayPrice)
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(isSelected ? theme.palette.onControl : theme.palette.foreground)
                .background(isSelected ? theme.palette.control : theme.palette.surface, in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(product.displayName), \(product.displayPrice)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
