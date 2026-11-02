import AlarmKit
import Foundation

/// AlarmKit operations used by an ongoing wake-up session.
struct AlarmRuntimeSystem {
    var states: @MainActor () throws -> [UUID: Alarm.State] = {
        try Dictionary(uniqueKeysWithValues: AlarmManager.shared.alarms.map { ($0.id, $0.state) })
    }
    var snooze: @MainActor (UUID) throws -> Void = AlarmScheduler.snooze
    var silence: @MainActor (UUID) throws -> Void = AlarmScheduler.silence
    var scheduleCountdown: @MainActor (AlarmRecord, UUID, TimeInterval, ClockAlarmMetadata.CountdownKind) async throws -> Void
        = AlarmScheduler.scheduleCountdown
}
