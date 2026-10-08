import AlarmKit
import Foundation
import SwiftUI

enum AlarmScheduler {
    static func schedule(_ alarm: AlarmRecord) async throws {
        let schedule = try alarm.alarmKitSchedule()
        let manager = AlarmManager.shared
        var authorization = manager.authorizationState
        if authorization == .notDetermined {
            authorization = try await manager.requestAuthorization()
        }
        guard authorization == .authorized else { throw SchedulingError.permissionDenied }

        let title = alarm.label.isEmpty ? "Alarm" : alarm.label
        let attributes = AlarmAttributes<ClockAlarmMetadata>(
            presentation: AlarmPresentation(alert: .init(title: "\(title)")),
            tintColor: .orange
        )
        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: schedule, attributes: attributes
        )
        _ = try await manager.schedule(id: alarm.id, configuration: configuration)
    }

    static func cancel(_ alarm: AlarmRecord) throws {
        let manager = AlarmManager.shared
        // A one-time alarm may have already finished in the system UI.
        if try manager.alarms.contains(where: { $0.id == alarm.id }) {
            try manager.cancel(id: alarm.id)
        }
    }

    enum SchedulingError: LocalizedError {
        case permissionDenied

        var errorDescription: String? {
            "Allow alarms for Clock in Settings before turning this alarm on."
        }
    }
}

private nonisolated struct ClockAlarmMetadata: AlarmMetadata {}
