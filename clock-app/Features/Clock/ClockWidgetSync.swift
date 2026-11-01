import OSLog
import SwiftUI
import WidgetKit

struct ClockWidgetSync: ViewModifier {
    @Environment(ThemeSettings.self) private var themeSettings
    @Environment(ClockDisplaySettings.self) private var clockSettings
    @Environment(\.scenePhase) private var scenePhase

    private var preferences: ClockWidgetPreferences {
        ClockWidgetPreferences(themeID: themeSettings.theme.id, timeFormat: clockSettings.format,
                               showsPeriod: clockSettings.showsPeriod)
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: preferences, initial: true) { _, value in synchronize(value) }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { synchronize(preferences) }
            }
    }

    private func synchronize(_ preferences: ClockWidgetPreferences) {
        guard let defaults = UserDefaults(suiteName: ClockWidgetPreferences.appGroup) else { return }
        do {
            if try ClockWidgetPreferencesStore(defaults: defaults).save(preferences) {
                WidgetCenter.shared.reloadTimelines(ofKind: ClockWidgetPreferences.kind)
            }
        } catch {
            Logger(subsystem: "dev.ambitionsoftware.clock-app", category: "ClockWidget")
                .error("Couldn't share clock preferences: \(error)")
        }
    }
}
