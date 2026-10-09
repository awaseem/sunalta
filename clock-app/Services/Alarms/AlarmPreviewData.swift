import SwiftData

enum AlarmPreviewData {
    static func makeContainer() throws -> ModelContainer {
        let container = try ModelContainer(
            for: AlarmRecord.self, AlarmStopTarget.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        container.mainContext.insert(try AlarmRecord(
            hour: 7, minute: 0, label: "Early start",
            repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday]
        ))
        container.mainContext.insert(try AlarmRecord(
            hour: 9, minute: 30, label: "Slow morning", isEnabled: false,
            repeatDays: [.saturday, .sunday]
        ))
        try container.mainContext.save()
        return container
    }
}
