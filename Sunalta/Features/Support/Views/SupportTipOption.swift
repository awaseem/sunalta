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
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(theme.palette.foreground)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(theme.colorScheme == .dark ? Color(white: 0.3) : .white)
                    }
                }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(product.displayName), \(product.displayPrice)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
