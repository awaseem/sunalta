import SwiftUI

struct AlarmRootView: View {
    @Environment(AlarmRuntime.self) private var runtime
    @Environment(ThemeSettings.self) private var themeSettings
    @Environment(\.scenePhase) private var scenePhase
    var observesAlarms = true

    var body: some View {
        ZStack {
            HomeScreen()
                .allowsHitTesting(!runtime.isAlarmPresented)
                .accessibilityHidden(runtime.isAlarmPresented)
            if runtime.isAlarmPresented, let alarm = runtime.activeAlarm {
                AlarmRingingScreen(alarm: alarm)
                    .id(alarm.id)
            }
        }
        .task { if observesAlarms { await runtime.observe() } }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await runtime.refresh() } }
        }
        .alert("Alarm needs attention", isPresented: Binding(
            get: { runtime.errorMessage != nil },
            set: { if !$0 { runtime.errorMessage = nil } }
        )) {
            Button("Retry") { Task { await runtime.refresh() } }
            Button("OK", role: .cancel) { runtime.errorMessage = nil }
        } message: {
            Text(runtime.errorMessage ?? "Please try again.")
        }
        // Apply the live theme here so an isolated preview can own its appearance.
        .appTheme(themeSettings.theme)
    }
}
