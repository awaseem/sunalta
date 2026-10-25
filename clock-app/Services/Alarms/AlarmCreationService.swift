import Foundation
import SwiftData

struct AlarmCreationService {
    let context: ModelContext
    var calendar: Calendar = .autoupdatingCurrent

    @discardableResult
    func create(_ draft: NewAlarmDraft) throws -> AlarmRecord {
        let target = try draft.exitPoint.makeStopTarget()
        let time = draft.timeComponents(calendar: calendar)
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let alarm = try AlarmRecord(
            hour: time.hour ?? 7, minute: time.minute ?? 0,
            label: name, isEnabled: false,
            repeatDays: draft.repeatDays, snoozeEnabled: draft.snoozeEnabled,
            snoozeDurationMinutes: draft.snoozeMinutes, exitPoint: draft.exitPoint.selection,
            stopTargets: target.map { [$0] } ?? []
        )
        if let target { context.insert(target) }
        context.insert(alarm)
        do {
            try context.save()
        } catch {
            // Undo only this creation, preserving unrelated pending edits in the context.
            context.delete(alarm)
            if let target { context.delete(target) }
            throw error
        }
        return alarm
    }
}
