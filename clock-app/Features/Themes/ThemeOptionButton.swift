import SwiftUI

struct ThemeOptionButton: View {
    @Environment(\.appTheme) private var currentTheme
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text("12")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(theme.clock.numeralColor)
                    .padding()
                    .background(theme.palette.background, in: .rect(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(currentTheme.palette.separator)
                    }
                    .accessibilityHidden(true)
                Text(theme.name)
                Spacer()
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(currentTheme.palette.selection)
                    .accessibilityHidden(true)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(currentTheme.palette.surface, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(theme.name)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
