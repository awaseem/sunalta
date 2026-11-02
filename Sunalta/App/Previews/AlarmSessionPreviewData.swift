#if DEBUG
import AlarmKit
import Foundation
import SwiftData

/// An isolated alarm session for reviewing the real screen without scheduling system alerts.
struct AlarmSessionPreviewData {
    let container: ModelContainer
    let alarm: AlarmRecord
    let runtime: AlarmRuntime
    let ringAgain: () -> Void

    init() throws {
        container = try ModelContainer(for: AlarmRecord.self, AlarmStopTarget.self,
                                        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let arguments = ProcessInfo.processInfo.arguments
        let alarm = try AlarmRecord(hour: 7, minute: 0, label: "Morning",
                                    snoozeDurationMinutes: 1,
                                    exitPoint: arguments.contains("--preview-scan-alarm") ? .qrCode : .normal)
        self.alarm = alarm
        alarm.configurationVersion = AlarmRuntime.configurationVersion
        container.mainContext.insert(alarm)
        try container.mainContext.save()
        var states: [UUID: Alarm.State] = [alarm.id: .alerting]
        let system = AlarmRuntimeSystem(states: { states }, snooze: { states[$0] = .countdown },
                                         silence: { states[$0] = nil },
                                         scheduleCountdown: { _, id, _, _ in states[id] = .countdown })
        runtime = AlarmRuntime(context: container.mainContext, system: system,
                               cancelAlarm: { states[$0] = nil })
        ringAgain = {
            if let retryID = alarm.retryAlarmIDs.last { states[retryID] = .alerting }
            else { states[alarm.id] = .alerting }
        }
    }
}
#endif
