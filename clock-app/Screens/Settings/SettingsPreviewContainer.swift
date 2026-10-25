import SwiftUI

/// Keeps preview selections and audio preferences separate from the installed app.
struct SettingsPreviewContainer: View {
    @State private var settings: ThemeSettings
    @State private var audioService: ClockAudioService

    init(theme: AppTheme) {
        let defaults = UserDefaults(suiteName: "ClockSettingsPreview") ?? .standard
        let settings = ThemeSettings(defaults: defaults)
        settings.select(theme)
        _settings = State(initialValue: settings)
        _audioService = State(initialValue: ClockAudioService(defaults: defaults))
    }

    var body: some View {
        ClockSettingsView()
            .environment(settings)
            .environment(audioService)
    }
}
