import AppIntents
import Foundation

// LiveActivityIntent executes in the containing app using its registered runtime.
struct ScanClockAlarmIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Scan to stop alarm"
    static var supportedModes: IntentModes { .foreground(.immediate) }
    static var isDiscoverable: Bool { false }

    @Parameter(title: "Alarm") var alarmID: String
    @Parameter(title: "System alarm") var systemID: String
    @Parameter(title: "Schedule") var token: String

    #if !CLOCK_WIDGET_EXTENSION
    @Dependency private var runtime: AlarmRuntime
    #endif

    init() {}

    init(alarmID: UUID, systemID: UUID, token: String) {
        self.alarmID = alarmID.uuidString
        self.systemID = systemID.uuidString
        self.token = token
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        #if !CLOCK_WIDGET_EXTENSION
        try await runtime.openScanner(alarmID: alarmID, systemID: systemID, token: token)
        #endif
        return .result()
    }
}
