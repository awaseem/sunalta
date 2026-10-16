import SwiftUI

struct AlarmExitPointOptionButton: View {
    @Environment(\.appTheme) private var theme
    let option: AlarmExitPoint
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .accessibilityHidden(true)
                Label(option.title, systemImage: option.symbol)
                    .font(.body.bold())
            }
            .padding()
            .frame(minHeight: 44)
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(isSelected ? theme.palette.onControl : theme.palette.foreground)
            .background(isSelected ? theme.palette.selection : theme.palette.surface, in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
        .accessibilityHint(option.detail)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("exit-point-\(option.rawValue)")
    }
}
