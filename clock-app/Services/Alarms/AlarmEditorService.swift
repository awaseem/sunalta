import AlarmKit
import Foundation
import SwiftData

struct AlarmEditorService {
    let context: ModelContext
    var calendar: Calendar = .autoupdatingCurrent
    var authorize: @MainActor () async throws -> Void = AlarmScheduler.authorize
    var schedule: @MainActor (AlarmRecord, UUID, Alarm.Schedule) async throws -> Void = AlarmScheduler.schedule
    var cancel: @MainActor (UUID) throws -> Void = AlarmScheduler.cancel
    var hasActiveSession: @MainActor (AlarmRecord) throws -> Bool = AlarmScheduler.hasActiveSession
    var save: @MainActor (ModelContext) throws -> Void = { try $0.save() }

    @discardableResult
    func create(_ draft: AlarmEditorDraft) throws -> AlarmRecord {
        try draft.validate(calendar: calendar)
        let target = try draft.exitPoint.makeStopTarget()
        let time = draft.timeComponents(calendar: calendar)
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let alarm = try AlarmRecord(
            hour: time.hour ?? 7, minute: time.minute ?? 0,
            label: name, isEnabled: false,
            repeatDays: draft.repeatDays, soundName: draft.soundSelection.storedValue,
            snoozeEnabled: draft.snoozeEnabled,
            snoozeDurationMinutes: draft.snoozeMinutes, exitPoint: draft.exitPoint.selection,
            stopTargets: target.map { [$0] } ?? []
        )
        if let target { context.insert(target) }
        context.insert(alarm)
        do {
            try save(context)
        } catch {
            // Undo only this creation, preserving unrelated pending edits in the context.
            context.delete(alarm)
            if let target { context.delete(target) }
            throw error
        }
        return alarm
    }

    /// Called through AlarmRuntime so saves, toggles, deletes and intent callbacks are serialized.
    func update(_ draft: AlarmEditorDraft, alarm: AlarmRecord) async throws {
        try draft.validate(calendar: calendar)
        try requireInactive(alarm)
        if alarm.isEnabled { try await authorize() }
        try Task.checkCancellation()
        // Authorization can suspend while the old alarm starts ringing or snoozing.
        try requireInactive(alarm)

        let previous = AlarmEditorDraft(alarm: alarm, calendar: calendar)
        let previousTargets = alarm.stopTargets
        let previousExitPointName = alarm.exitPointName
        let previousToken = alarm.scheduleToken
        let previousCompletion = alarm.lastCompletedAt
        let previousVersion = alarm.configurationVersion
        let replacement = try stopTarget(for: draft, reusing: previousTargets)
        let insertedTarget = replacement.flatMap { target in
            previousTargets.contains(where: { $0.id == target.id }) ? nil : target
        }
        var cancelledSchedule = false

        do {
            if let insertedTarget { context.insert(insertedTarget) }
            try apply(draft, to: alarm, targets: replacement.map { [$0] } ?? [])
            if previous.exitPoint != draft.exitPoint { alarm.exitPointName = nil }
            if alarm.isEnabled {
                alarm.scheduleToken = UUID().uuidString
                alarm.lastCompletedAt = nil
                alarm.configurationVersion = AlarmRuntime.configurationVersion
            }
            try save(context)
            if alarm.isEnabled {
                // Reuse the record's ID and remove its old schedule before installing the replacement.
                try cancel(alarm.id)
                cancelledSchedule = true
                try await schedule(alarm, alarm.id, alarm.alarmKitSchedule())
            }
        } catch {
            let operationError = error
            var recoveryError: Error?
            do {
                try apply(previous, to: alarm, targets: previousTargets)
                alarm.label = previous.name
                alarm.exitPointName = previousExitPointName
                alarm.scheduleToken = previousToken
                alarm.lastCompletedAt = previousCompletion
                alarm.configurationVersion = previousVersion
                if let insertedTarget { context.delete(insertedTarget) }
                try save(context)
            } catch { recoveryError = error }
            if cancelledSchedule {
                do {
                    try cancel(alarm.id)
                    try await schedule(alarm, alarm.id, alarm.alarmKitSchedule())
                } catch {
                    recoveryError = recoveryError.map {
                        AlarmRecoveryError(operationError: $0, recoveryError: error)
                    } ?? error
                }
            }
            if let recoveryError {
                throw AlarmRecoveryError(operationError: operationError, recoveryError: recoveryError)
            }
            throw operationError
        }
    }

    private func requireInactive(_ alarm: AlarmRecord) throws {
        guard alarm.modelContext != nil, !alarm.isDeleted else { throw AlarmRuntime.SessionError.alarmDeleted }
        guard alarm.pendingSince == nil, alarm.snoozedUntil == nil, alarm.retryAlarmIDs.isEmpty,
              try !hasActiveSession(alarm) else {
            throw AlarmRuntime.SessionError.scanRequired
        }
    }

    private func stopTarget(for draft: AlarmEditorDraft, reusing targets: [AlarmStopTarget]) throws -> AlarmStopTarget? {
        guard let code = draft.exitPoint.scannedCode else { return nil }
        if let existing = targets.first(where: { $0.matches(codeValue: code.value, kind: code.kind) }) {
            return existing
        }
        return try draft.exitPoint.makeStopTarget()
    }

    private func apply(_ draft: AlarmEditorDraft, to alarm: AlarmRecord, targets: [AlarmStopTarget]) throws {
        let time = draft.timeComponents(calendar: calendar)
        try alarm.setTime(hour: time.hour ?? 7, minute: time.minute ?? 0)
        try alarm.setSnoozeDuration(minutes: draft.snoozeMinutes)
        try alarm.setExitPoint(draft.exitPoint.selection, stopTargets: targets)
        alarm.label = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        alarm.repeatDays = draft.repeatDays
        alarm.snoozeEnabled = draft.snoozeEnabled
        alarm.soundSelection = draft.soundSelection
        try alarm.validate()
    }
}
