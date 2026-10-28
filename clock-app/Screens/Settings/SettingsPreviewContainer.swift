import SwiftUI

/// Keeps preview selections and audio preferences separate from the installed app.
struct SettingsPreviewContainer: View {
    @State private var settings: ThemeSettings
    @State private var clockSettings: ClockDisplaySettings
    @State private var audioService: ClockAudioService
    @State private var tips = TipStore()

    init(theme: AppTheme, timeFormat: ClockTimeFormat = .twentyFourHour) {
        let defaults = PreviewDefaults.make(timeFormat: timeFormat)
        let settings = ThemeSettings(defaults: defaults)
        settings.select(theme)
        _settings = State(initialValue: settings)
        _clockSettings = State(initialValue: ClockDisplaySettings(defaults: defaults))
        _audioService = State(initialValue: ClockAudioService(defaults: defaults))
    }

    var body: some View {
        ClockSettingsView()
            .environment(settings)
            .environment(clockSettings)
            .environment(audioService)
            .environment(tips)
    }
}
