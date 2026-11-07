import SwiftData

enum AlarmStore {
    static func makeContainer() throws -> ModelContainer {
        try ModelContainer(for: AlarmRecord.self, AlarmStopTarget.self)
    }
}
