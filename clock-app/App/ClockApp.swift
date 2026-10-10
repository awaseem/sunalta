import SwiftUI
import SwiftData
import AppIntents

@main
struct ClockApp: App {
    private let container: ModelContainer
    @State private var runtime: AlarmRuntime
    @State private var themeSettings = ThemeSettings()

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
            AlarmRootView()
                .environment(runtime)
                .environment(themeSettings)
                .appTheme(themeSettings.theme)
        }
        .modelContainer(container)
    }
}
