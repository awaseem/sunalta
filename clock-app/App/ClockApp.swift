import SwiftUI
import SwiftData

@main
struct ClockApp: App {
    var body: some Scene {
        WindowGroup {
            HomeScreen()
        }
        .modelContainer(for: [AlarmRecord.self, AlarmStopTarget.self])
    }
}
