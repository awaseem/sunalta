import AlarmKit
import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AlarmRuntime {
    nonisolated static let retryInterval: TimeInterval = 30
    private static let configurationVersion = 1

    private(set) var activeAlarm: AlarmRecord?
    private(set) var scanRequestID: UUID?
    var errorMessage: String?

    private let context: ModelContext
    private var operations: [UUID: (id: UUID, task: Task<Void, Error>)] = [:]

    init(context: ModelContext) {
        self.context = context
    }

    func observe() async {
        await refresh()
        for await _ in AlarmManager.shared.alarmUpdates {
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }

    func refresh() async {
        do {
            for alarm in try context.fetch(FetchDescriptor<AlarmRecord>()) {
                guard operations[alarm.id] == nil else { continue }
                var systemAlarms = try AlarmManager.shared.alarms
                // Upgrade alarms saved before the dismissal intents were added.
                if alarm.configurationVersion != Self.configurationVersion, alarm.isEnabled, alarm.pendingSince == nil,
                   systemAlarms.contains(where: { $0.id == alarm.id && $0.state == .scheduled }) {
                    try await setEnabled(true, for: alarm)
                    systemAlarms = try AlarmManager.shared.alarms
                }
                let ids = Set([alarm.id] + alarm.retryAlarmIDs)
                let isRinging = systemAlarms.contains {
                    ids.contains($0.id) && $0.state == .alerting
                        && acceptsCallback(alarm, sourceID: $0.id, token: alarm.scheduleToken ?? "")
                }
                if isRinging { try activate(alarm) }
                if alarm.pendingSince != nil, !isRinging {
                    try await perform(for: alarm.id) {
                        guard alarm.pendingSince != nil else { return }
                        if alarm.exitPoint == .normal,
                           (try AlarmManager.shared.alarms).contains(where: { $0.id == alarm.id && $0.state == .countdown }) {
                            alarm.pendingSince = nil
                        } else if alarm.exitPoint == .normal { try self.complete(alarm) }
                        else { try await self.ensureRetry(alarm) }
                    }
                }
                if operations[alarm.id] == nil {
                    let scheduled = try AlarmManager.shared.alarms
                    alarm.isEnabled = alarm.pendingSince != nil || scheduled.contains { $0.id == alarm.id }
                }
            }
            try context.save()
            try showPendingAlarm()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setEnabled(_ enabled: Bool, for alarm: AlarmRecord) async throws {
        try await perform(for: alarm.id) {
            guard alarm.pendingSince == nil else { throw SessionError.scanRequired }
            if enabled {
                let schedule = try alarm.alarmKitSchedule()
                try await AlarmScheduler.authorize()
                let oldToken = alarm.scheduleToken
                let oldDate = alarm.lastCompletedAt
                let oldVersion = alarm.configurationVersion
                alarm.scheduleToken = UUID().uuidString
                alarm.lastCompletedAt = nil
                alarm.configurationVersion = Self.configurationVersion
                do {
                    try self.context.save()
                    try await AlarmScheduler.schedule(alarm, id: alarm.id, schedule: schedule)
                } catch {
                    alarm.scheduleToken = oldToken
                    alarm.lastCompletedAt = oldDate
                    alarm.configurationVersion = oldVersion
                    try self.saveRestoredState(after: error)
                }
            } else {
                try AlarmScheduler.cancel(id: alarm.id)
                try self.cancelRetries(alarm)
                alarm.scheduleToken = nil
                alarm.lastCompletedAt = nil
                alarm.configurationVersion = nil
                alarm.snoozedUntil = nil
            }
            alarm.isEnabled = enabled
            try self.context.save()
        }
    }

    func handleStop(alarmID: String, systemID: String, token: String) async throws {
        guard let id = UUID(uuidString: alarmID), let sourceID = UUID(uuidString: systemID) else { return }
        try await perform(for: id) {
            guard let alarm = try self.alarm(id), self.acceptsCallback(alarm, sourceID: sourceID, token: token) else { return }
            try self.activate(alarm)
            if alarm.exitPoint == .normal {
                try self.complete(alarm)
            } else {
                // System Stop has silenced this alert. The wake-up session is still pending.
                try await self.ensureRetry(alarm, stoppedID: sourceID)
                try AlarmScheduler.silence(id: sourceID)
            }
        }
    }

    func openScanner(alarmID: String, systemID: String, token: String) async throws {
        guard let id = UUID(uuidString: alarmID), let sourceID = UUID(uuidString: systemID) else { return }
        try await perform(for: id) {
            guard let alarm = try self.alarm(id), alarm.exitPoint != .normal,
                  self.acceptsCallback(alarm, sourceID: sourceID, token: token) else { return }
            try self.activate(alarm)
            try await self.quietForScan(alarm)
            self.activeAlarm = alarm
            self.scanRequestID = UUID()
        }
    }

    func prepareToScan(_ alarm: AlarmRecord) async throws {
        try await perform(for: alarm.id) {
            guard alarm.pendingSince != nil, alarm.exitPoint != .normal else { return }
            try await self.quietForScan(alarm)
        }
    }

    func snooze(_ alarm: AlarmRecord) async throws {
        try await perform(for: alarm.id) {
            guard alarm.pendingSince != nil, alarm.snoozeEnabled else { return }
            try await self.startSnooze(alarm)
        }
    }

    func snooze(alarmID: String, systemID: String, token: String) async throws {
        guard let id = UUID(uuidString: alarmID), let sourceID = UUID(uuidString: systemID) else { return }
        try await perform(for: id) {
            guard let alarm = try self.alarm(id), alarm.snoozeEnabled,
                  self.acceptsCallback(alarm, sourceID: sourceID, token: token) else { return }
            try await self.startSnooze(alarm)
        }
    }

    private func startSnooze(_ alarm: AlarmRecord) async throws {
        let duration = TimeInterval(alarm.snoozeDurationMinutes * 60)
        if alarm.exitPoint == .normal {
            try AlarmScheduler.snooze(id: alarm.id)
            alarm.pendingSince = nil
            alarm.snoozedUntil = .now.addingTimeInterval(duration)
        } else {
            try activate(alarm)
            try await ensureRetry(alarm, duration: duration, kind: .snooze, replace: true)
            try AlarmScheduler.silence(id: alarm.id)
            alarm.snoozedUntil = alarm.nextRetryAt
        }
        try context.save()
        try showPendingAlarm()
    }

    func finish(_ alarm: AlarmRecord, code: String? = nil, kind: AlarmStopTarget.Kind? = nil) async throws {
        try await perform(for: alarm.id) {
            guard alarm.pendingSince != nil else { return }
            if alarm.exitPoint != .normal {
                guard let code, let kind, alarm.acceptsScan(codeValue: code, kind: kind) else {
                    throw SessionError.wrongScan
                }
            }
            try self.complete(alarm)
        }
    }

    private func quietForScan(_ alarm: AlarmRecord) async throws {
        // Schedule the next alert before silencing anything. Scanning again doesn't
        // extend an existing quiet window, and leaving the app doesn't cancel it.
        try await ensureRetry(alarm)
        try AlarmScheduler.silence(id: alarm.id)
    }

    private func ensureRetry(_ alarm: AlarmRecord, stoppedID: UUID? = nil,
                             duration: TimeInterval = retryInterval,
                             kind: ClockAlarmMetadata.CountdownKind = .scanReminder,
                             replace: Bool = false) async throws {
        let systemAlarms = try AlarmManager.shared.alarms
        if !replace, let id = alarm.retryAlarmIDs.last, id != stoppedID,
           let date = alarm.nextRetryAt, date > .now,
           systemAlarms.contains(where: { $0.id == id && ($0.state == .scheduled || $0.state == .countdown) }) {
            return
        }

        let oldIDs = alarm.retryAlarmIDs
        let oldDate = alarm.nextRetryAt
        let id = UUID()
        let date = Date.now.addingTimeInterval(duration)
        alarm.retryAlarmIDs.append(id)
        alarm.nextRetryAt = date
        do {
            // Persist ownership before scheduling so a cold launch can cancel it.
            try context.save()
            try await AlarmScheduler.scheduleCountdown(alarm, id: id, duration: duration, kind: kind)
        } catch {
            alarm.retryAlarmIDs = oldIDs
            alarm.nextRetryAt = oldDate
            try saveRestoredState(after: error)
        }
        for oldID in oldIDs {
            try AlarmScheduler.cancel(id: oldID)
            alarm.retryAlarmIDs.removeAll { $0 == oldID }
        }
        try context.save()
    }

    private func complete(_ alarm: AlarmRecord) throws {
        try cancelRetries(alarm)
        if alarm.repeatDays.isEmpty {
            try AlarmScheduler.cancel(id: alarm.id)
            alarm.isEnabled = false
            alarm.scheduleToken = nil
        } else {
            // Stop only today's ring; keep AlarmKit's weekly recurrence intact.
            try AlarmScheduler.silence(id: alarm.id)
        }
        alarm.pendingSince = nil
        alarm.snoozedUntil = nil
        alarm.lastCompletedAt = .now
        try context.save()
        try showPendingAlarm()
    }

    private func cancelRetries(_ alarm: AlarmRecord) throws {
        for id in alarm.retryAlarmIDs {
            try AlarmScheduler.cancel(id: id)
            alarm.retryAlarmIDs.removeAll { $0 == id }
        }
        alarm.nextRetryAt = nil
    }

    private func activate(_ alarm: AlarmRecord) throws {
        if alarm.pendingSince == nil { alarm.pendingSince = .now }
        alarm.snoozedUntil = nil
        alarm.isEnabled = true
        try context.save()
        if activeAlarm?.pendingSince == nil { activeAlarm = alarm }
    }

    private func acceptsCallback(_ alarm: AlarmRecord, sourceID: UUID, token: String) -> Bool {
        guard (alarm.scheduleToken ?? "") == token else { return false }
        if sourceID == alarm.id {
            // Ignore a late callback from an occurrence already completed by a scan.
            guard let completed = alarm.lastCompletedAt else { return true }
            let occurrence = alarm.latestOccurrence(before: Date.now.addingTimeInterval(1))
            return occurrence.map { $0 > completed } ?? false
        }
        return alarm.retryAlarmIDs.contains(sourceID)
    }

    private func alarm(_ id: UUID) throws -> AlarmRecord? {
        var descriptor = FetchDescriptor<AlarmRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func showPendingAlarm() throws {
        if let activeAlarm, activeAlarm.pendingSince != nil,
           activeAlarm.snoozedUntil.map({ $0 > .now }) != true { return }
        let now = Date.now
        var descriptor = FetchDescriptor<AlarmRecord>(
            predicate: #Predicate { $0.pendingSince != nil && ($0.snoozedUntil ?? now) <= now },
            sortBy: [SortDescriptor(\AlarmRecord.pendingSince)]
        )
        descriptor.fetchLimit = 1
        activeAlarm = try context.fetch(descriptor).first
        scanRequestID = nil
    }

    private func perform(for id: UUID, action: @escaping @MainActor () async throws -> Void) async throws {
        // Intents and camera callbacks can arrive while scheduling is suspended.
        // Serialize per alarm so a late retry cannot survive a successful scan.
        let previous = operations[id]?.task
        let operationID = UUID()
        let task = Task { @MainActor in
            _ = await previous?.result
            try Task.checkCancellation()
            try await action()
        }
        operations[id] = (operationID, task)
        defer { if operations[id]?.id == operationID { operations[id] = nil } }
        try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    private func saveRestoredState(after operationError: Error) throws -> Never {
        do {
            try context.save()
        } catch {
            throw AlarmRecoveryError(operationError: operationError, persistenceError: error)
        }
        throw operationError
    }
}
