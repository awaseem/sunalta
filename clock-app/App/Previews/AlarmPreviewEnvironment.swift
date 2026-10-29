import SwiftData
import SwiftUI

struct AlarmPreviewEnvironment<Content: View>: View {
    private let container: ModelContainer
    private let content: Content
    @State private var runtime: AlarmRuntime
    @State private var tips = TipStore()
    @State private var audioService: ClockAudioService
    @State private var themeSettings: ThemeSettings
    @State private var clockSettings: ClockDisplaySettings

    init(container: ModelContainer, timeFormat: ClockTimeFormat, content: Content) {
        let defaults = PreviewDefaults.make(timeFormat: timeFormat)
        _audioService = State(initialValue: ClockAudioService(defaults: defaults))
        _themeSettings = State(initialValue: ThemeSettings(defaults: defaults))
        _clockSettings = State(initialValue: ClockDisplaySettings(defaults: defaults))
        self.container = container
        self.content = content
        _runtime = State(initialValue: AlarmRuntime(context: container.mainContext))
    }

    var body: some View {
        content
            .modelContainer(container)
            .environment(runtime)
            .environment(themeSettings)
            .environment(clockSettings)
            .environment(audioService)
            .environment(tips)
            .appTheme(themeSettings.theme)
    }
}
