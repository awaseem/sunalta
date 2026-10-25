import SwiftUI

struct SettingsThemeButton: View {
    @Environment(\.appTheme) private var currentTheme
    @ScaledMetric(relativeTo: .subheadline) private var swatchSize = 20
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack {
                theme.palette.background
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        ThemeMaterialPreview(theme: theme)
                            .allowsHitTesting(false)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Circle()
                            .fill(theme.palette.selection)
                            .frame(width: swatchSize, height: swatchSize)
                            .padding()
                    }
                    .clipShape(.rect(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(isSelected ? currentTheme.palette.foreground
                                          : currentTheme.palette.separator,
                                          lineWidth: isSelected ? 2 : 1)
                    }
                HStack {
                    Text(theme.name)
                        .fixedSize(horizontal: false, vertical: true)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(currentTheme.palette.selection)
                    }
                }
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(theme.name)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint("Changes the clock and app appearance")
    }
}
