import AppIntents
import Foundation

// LiveActivityIntent executes in the containing app. The extension shares these
// declarations so its buttons can invoke the app's alarm service.
struct StopClockAlarmIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop clock alarm"
    static var supportedModes: IntentModes { .background }
    static var isDiscoverable: Bool { false }

    @Parameter(title: "Alarm") var alarmID: String
    @Parameter(title: "System alarm") var systemID: String
    @Parameter(title: "Schedule") var token: String

    init() {}

    init(alarmID: UUID, systemID: UUID, token: String) {
        self.alarmID = alarmID.uuidString
        self.systemID = systemID.uuidString
        self.token = token
    }

    func perform() async throws -> some IntentResult {
        #if !CLOCK_WIDGET_EXTENSION
        try await AlarmRuntime.shared.handleStop(alarmID: alarmID, systemID: systemID, token: token)
        #endif
        return .result()
    }
}

struct ScanClockAlarmIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Scan to stop alarm"
    static var supportedModes: IntentModes { .foreground(.immediate) }
    static var isDiscoverable: Bool { false }

    @Parameter(title: "Alarm") var alarmID: String
    @Parameter(title: "System alarm") var systemID: String
    @Parameter(title: "Schedule") var token: String

    init() {}

    init(alarmID: UUID, systemID: UUID, token: String) {
        self.alarmID = alarmID.uuidString
        self.systemID = systemID.uuidString
        self.token = token
    }

    func perform() async throws -> some IntentResult {
        #if !CLOCK_WIDGET_EXTENSION
        try await AlarmRuntime.shared.openScanner(alarmID: alarmID, systemID: systemID, token: token)
        #endif
        return .result()
    }
}

struct SnoozeClockAlarmIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Snooze clock alarm"
    static var supportedModes: IntentModes { .background }
    static var isDiscoverable: Bool { false }

    @Parameter(title: "Alarm") var alarmID: String
    @Parameter(title: "System alarm") var systemID: String
    @Parameter(title: "Schedule") var token: String

    init() {}

    init(alarmID: UUID, systemID: UUID, token: String) {
        self.alarmID = alarmID.uuidString
        self.systemID = systemID.uuidString
        self.token = token
    }

    func perform() async throws -> some IntentResult {
        #if !CLOCK_WIDGET_EXTENSION
        try await AlarmRuntime.shared.snooze(alarmID: alarmID, systemID: systemID, token: token)
        #endif
        return .result()
    }
}
