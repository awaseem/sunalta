import SwiftUI
import SwiftData
import AppIntents

@main
struct SunaltaApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let container: ModelContainer
    @State private var runtime: AlarmRuntime
    @State private var themeSettings = ThemeSettings()
    @State private var clockSettings = ClockDisplaySettings()
    @State private var audioService = ClockAudioService()
    @State private var appIcon = ThemeAppIcon()
    @State private var tips = TipStore()

    init() {
        do {
            let container = try AlarmStore.makeContainer()
            self.container = container
            let runtime = AlarmRuntime(context: container.mainContext)
            _runtime = State(initialValue: runtime)
            // Register during initialization, including launches triggered by an intent.
            AppDependencyManager.shared.add(dependency: runtime)
        } catch {
            // Preserve the existing store rather than resetting it after a migration failure.
            fatalError("Couldn't open the alarm store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG && targetEnvironment(simulator)
                // Launch with --preview-alarms to review an isolated, populated list.
                if ProcessInfo.processInfo.arguments.contains("--preview-active-alarm") {
                    AlarmSessionPreview()
                } else if ProcessInfo.processInfo.arguments.contains("--preview-alarms") {
                    AlarmPreviewContainer { HomeScreen() }
                } else {
                    AlarmRootView()
                }
                #else
                AlarmRootView()
                #endif
            }
                .modifier(ClockWidgetSync())
                .environment(runtime)
                .environment(themeSettings)
                .environment(clockSettings)
                .environment(audioService)
                .environment(tips)
                .task { await tips.observeTransactions() }
                .task(id: themeSettings.theme.id) {
                    await appIcon.synchronize(with: themeSettings.theme)
                }
                .task(id: scenePhase) {
                    if scenePhase == .active {
                        await appIcon.synchronize(with: themeSettings.theme)
                    }
                }
                .task {
                    #if DEBUG
                    await ThemeIconExporter.exportIfRequested()
                    await ClockWidgetSceneExporter.exportIfRequested()
                    #endif
                }
        }
        .modelContainer(container)
    }
}
