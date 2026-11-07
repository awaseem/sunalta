import SwiftData

enum AlarmPreviewData {
    static func makeContainer() throws -> ModelContainer {
        let container = try ModelContainer(
            for: AlarmRecord.self, AlarmStopTarget.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        container.mainContext.insert(try AlarmRecord(
            hour: 6, minute: 15, label: "Morning workout",
            repeatDays: [.monday, .wednesday, .friday],
            snoozeEnabled: false, exitPoint: .nfc
        ))
        container.mainContext.insert(try AlarmRecord(
            hour: 7, minute: 0, label: "Early start",
            repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday]
        ))
        container.mainContext.insert(try AlarmRecord(
            hour: 7, minute: 45, label: "School run",
            repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            exitPoint: .qrCode
        ))
        container.mainContext.insert(try AlarmRecord(
            hour: 8, minute: 30, label: "Start the day", isEnabled: false
        ))
        container.mainContext.insert(try AlarmRecord(
            hour: 9, minute: 30, label: "Slow morning", isEnabled: false,
            repeatDays: [.saturday, .sunday]
        ))
        container.mainContext.insert(try AlarmRecord(
            hour: 12, minute: 30, label: "Lunch break",
            repeatDays: Set(ClockWeekday.allCases)
        ))
        container.mainContext.insert(try AlarmRecord(
            hour: 15, minute: 0, label: "Afternoon reset", isEnabled: false,
            snoozeDurationMinutes: 15
        ))
        container.mainContext.insert(try AlarmRecord(
            hour: 21, minute: 45, label: "Time to wind down",
            repeatDays: Set(ClockWeekday.allCases), snoozeEnabled: false
        ))
        try container.mainContext.save()
        return container
    }
}
