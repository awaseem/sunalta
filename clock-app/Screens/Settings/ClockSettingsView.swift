import SwiftUI

struct ClockSettingsView: View {
    @Environment(ThemeSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .body) private var sectionSpacing = 28

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: sectionSpacing) {
                    SettingsAppearanceSection()
                    SettingsClockSection()
                    SettingsSoundSection()
                    SettingsAboutSection()
                }
                .padding()
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: SettingsDestination.self) { destination in
                switch destination {
                case .support: ClockSupportView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close settings", systemImage: "xmark") { dismiss() }
                        .labelStyle(.iconOnly)
                }
            }
        }
        .appTheme(settings.theme)
        .presentationBackground(settings.theme.palette.background)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationSizing(.form)
    }
}

#Preview("Settings") {
    SettingsPreviewContainer(theme: .white)
}

#Preview("12-hour settings") {
    SettingsPreviewContainer(theme: .white, timeFormat: .twelveHour)
}

#Preview("Midnight settings") {
    SettingsPreviewContainer(theme: .midnight)
}

#Preview("Grass settings · large text") {
    SettingsPreviewContainer(theme: .grass)
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Theme without music") {
    SettingsPreviewContainer(theme: AppTheme(
        id: "silent-preview", name: "Silent", colorScheme: .light,
        palette: AppTheme.white.palette
    ))
}
