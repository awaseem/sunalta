import SwiftUI
import SwiftData

@main
struct ClockApp: App {
    var body: some Scene {
        WindowGroup {
            AlarmRootView()
                .environment(AlarmRuntime.shared)
        }
        .modelContainer(AlarmStore.container)
    }
}
