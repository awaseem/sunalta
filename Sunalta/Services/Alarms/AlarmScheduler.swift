import AlarmKit
import Foundation
import SwiftUI

enum AlarmScheduler {
    static func hasActiveSession(_ alarm: AlarmRecord) throws -> Bool {
        let ids = Set([alarm.id] + alarm.retryAlarmIDs)
        return try AlarmManager.shared.alarms.contains { ids.contains($0.id) && $0.state != .scheduled }
    }

    static func authorize() async throws {
        let manager = AlarmManager.shared
        var authorization = manager.authorizationState
        if authorization == .notDetermined {
            authorization = try await manager.requestAuthorization()
        }
        guard authorization == .authorized else { throw SchedulingError.permissionDenied }
    }

    static func schedule(_ alarm: AlarmRecord, id: UUID, schedule: Alarm.Schedule) async throws {
        let configuration = configuration(
            alarm, id: id, schedule: schedule,
            duration: alarm.snoozeEnabled ? .init(preAlert: nil, postAlert: TimeInterval(alarm.snoozeDurationMinutes * 60)) : nil,
            kind: .snooze
        )
        _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
    }

    static func scheduleCountdown(_ alarm: AlarmRecord, id: UUID, duration: TimeInterval,
                                  kind: ClockAlarmMetadata.CountdownKind) async throws {
        let configuration = configuration(
            alarm, id: id, schedule: nil,
            duration: .init(preAlert: duration, postAlert: nil), kind: kind
        )
        _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
    }

    private static func configuration(_ alarm: AlarmRecord, id: UUID, schedule: Alarm.Schedule?,
                                      duration: Alarm.CountdownDuration?, kind: ClockAlarmMetadata.CountdownKind)
        -> sending AlarmManager.AlarmConfiguration<ClockAlarmMetadata> {
        let title = alarm.label.isEmpty ? "Alarm" : alarm.label
        let needsScan = alarm.exitPoint != .normal
        let token = alarm.scheduleToken ?? ""
        let secondaryButton: AlarmButton? = needsScan
            ? .init(text: alarm.exitPoint == .nfc ? "Scan NFC" : "Scan QR", textColor: .black,
                    systemImageName: alarm.exitPoint.symbol)
            : alarm.snoozeEnabled ? .init(text: "Snooze", textColor: .black, systemImageName: "zzz") : nil
        let attributes = AlarmAttributes<ClockAlarmMetadata>(
            presentation: AlarmPresentation(alert: .init(
                title: "\(title)",
                secondaryButton: secondaryButton,
                secondaryButtonBehavior: secondaryButton == nil ? nil : needsScan ? .custom : .countdown
            ), countdown: duration == nil ? nil : .init(title: "\(title)")),
            metadata: .init(alarmID: alarm.id, token: token, title: title,
                            scanSymbol: needsScan ? alarm.exitPoint.symbol : nil, countdownKind: kind),
            // AlarmKit owns the dark alert surface; use Sunalta's contrasting monochrome controls.
            tintColor: .white
        )
        return .init(
            countdownDuration: duration, schedule: schedule, attributes: attributes,
            stopIntent: StopClockAlarmIntent(alarmID: alarm.id, systemID: id, token: token),
            secondaryIntent: needsScan
                ? ScanClockAlarmIntent(alarmID: alarm.id, systemID: id, token: token)
                : alarm.snoozeEnabled ? SnoozeClockAlarmIntent(alarmID: alarm.id, systemID: id, token: token) : nil,
            sound: AlarmSoundResolver().alertSound(for: alarm.soundSelection)
        )
    }

    static func cancel(id: UUID) throws {
        let manager = AlarmManager.shared
        if try manager.alarms.contains(where: { $0.id == id }) {
            try manager.cancel(id: id)
        }
    }

    static func silence(id: UUID) throws {
        let manager = AlarmManager.shared
        if try manager.alarms.contains(where: { $0.id == id && $0.state != .scheduled }) {
            try manager.stop(id: id)
        }
    }

    static func snooze(id: UUID) throws {
        let manager = AlarmManager.shared
        if try manager.alarms.contains(where: { $0.id == id && $0.state == .alerting }) {
            try manager.countdown(id: id)
        }
    }

}
