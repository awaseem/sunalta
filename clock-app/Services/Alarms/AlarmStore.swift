import SwiftData

enum AlarmStore {
    // LiveActivityIntent runs in the app process, including on a cold launch.
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: AlarmRecord.self, AlarmStopTarget.self)
        } catch {
            fatalError("Couldn't open the alarm store: \(error)")
        }
    }()
}
