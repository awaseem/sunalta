import SwiftUI

struct SettingsAppearanceSection: View {
    @Environment(ThemeSettings.self) private var settings
    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading) {
            Text("Appearance")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text("Choose a feel for your clock.")
                .font(.subheadline)
                .foregroundStyle(theme.palette.secondaryForeground)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()),
                                     count: dynamicTypeSize.isAccessibilitySize ? 1 : AppTheme.available.count)) {
                ForEach(AppTheme.available) { option in
                    SettingsThemeButton(theme: settings.appearance(for: option),
                                        isSelected: settings.theme.id == option.id) {
                        settings.select(option)
                    }
                }
            }
            .padding(.vertical)

            if let message = settings.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(theme.palette.error)
                Button("Reset this theme", action: settings.resetCurrentTheme)
                    .buttonStyle(.appCapsule)
            }
        }
    }
}
