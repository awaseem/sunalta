import SwiftUI
import SwiftData

@main
struct clock_appApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [AlarmRecord.self, AlarmStopTarget.self])
    }
}
