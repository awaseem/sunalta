import SwiftUI

struct ThemeSelectionMenu: View {
    @Environment(ThemeSettings.self) private var settings

    var body: some View {
        Menu("Appearance", systemImage: "circle.lefthalf.filled") {
            Picker("Theme", selection: Binding(
                get: { settings.theme.id },
                set: { settings.select(AppTheme.resolve(id: $0)) }
            )) {
                ForEach(AppTheme.available) { theme in
                    Text(theme.name).tag(theme.id)
                }
            }
        }
        .labelStyle(.iconOnly)
        .font(.subheadline)
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityHint("Choose the clock and alarm theme")
    }
}
