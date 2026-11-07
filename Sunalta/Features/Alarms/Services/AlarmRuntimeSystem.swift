import AlarmKit
import Foundation

/// AlarmKit operations used to schedule alarms and manage wake-up sessions.
struct AlarmRuntimeSystem {
    var authorize: @MainActor () async throws -> Void = AlarmScheduler.authorize
    var schedule: @MainActor (AlarmRecord, UUID, Alarm.Schedule) async throws -> Void = AlarmScheduler.schedule
    var states: @MainActor () throws -> [UUID: Alarm.State] = {
        try Dictionary(uniqueKeysWithValues: AlarmManager.shared.alarms.map { ($0.id, $0.state) })
    }
    var snooze: @MainActor (UUID) throws -> Void = AlarmScheduler.snooze
    var silence: @MainActor (UUID) throws -> Void = AlarmScheduler.silence
    var scheduleCountdown: @MainActor (AlarmRecord, UUID, TimeInterval, ClockAlarmMetadata.CountdownKind) async throws -> Void
        = AlarmScheduler.scheduleCountdown
}
