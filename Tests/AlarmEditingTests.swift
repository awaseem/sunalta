import AlarmKit
import Foundation
import SwiftData
import Testing
@testable import clock_app

@MainActor
struct AlarmEditingTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(for: AlarmRecord.self, AlarmStopTarget.self,
                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func makeService(_ context: ModelContext) -> AlarmEditorService {
        AlarmEditorService(context: context, calendar: calendar, authorize: {},
                           schedule: { _, _, _ in }, cancel: { _ in }, hasActiveSession: { _ in false })
    }

    private func insertAlarm(in context: ModelContext, enabled: Bool = true) throws -> AlarmRecord {
        let target = try AlarmStopTarget(name: "Kitchen", kind: .qrCode, codeValue: "https://example.com/Wake\n")
        let alarm = try AlarmRecord(hour: 6, minute: 45, label: "Early start", isEnabled: enabled,
                                   repeatDays: [.monday, .friday], soundName: "birdsong.caf",
                                   snoozeEnabled: false, snoozeDurationMinutes: 9,
                                   exitPoint: .qrCode, stopTargets: [target], exitPointName: "Kitchen")
        alarm.scheduleToken = enabled ? "old-token" : nil
        alarm.configurationVersion = enabled ? AlarmRuntime.configurationVersion : nil
        context.insert(alarm)
        try context.save()
        return alarm
    }

    @Test func discardingAPrefilledDraftLeavesTheRecordAndScanTargetUntouched() throws {
        let container = try makeContainer()
        let alarm = try insertAlarm(in: container.mainContext)
        var draft = AlarmEditorDraft(alarm: alarm, calendar: calendar)
        #expect(draft.timeComponents(calendar: calendar).hour == 6)
        #expect(draft.timeComponents(calendar: calendar).minute == 45)
        #expect(draft.repeatDays == [.monday, .friday])
        #expect(!draft.snoozeEnabled && draft.snoozeMinutes == 9)
        #expect(draft.name == "Early start")
        #expect(draft.exitPoint.scannedCode?.value == "https://example.com/Wake\n")

        draft.name = "Unsaved"
        draft.repeatDays = []
        draft.snoozeEnabled = true
        draft.exitPoint.select(.normal)

        #expect(!container.mainContext.hasChanges)
        #expect(alarm.label == "Early start" && alarm.exitPoint == .qrCode)
        let saved = try #require(ModelContext(container).fetch(FetchDescriptor<AlarmRecord>()).first)
        #expect(saved.scheduleToken == "old-token")
        #expect(saved.stopTargets.first?.codeValue == "https://example.com/Wake\n")
    }

    @Test func disabledEditPersistsInPlaceWithoutSchedulingOrChangingASharedTarget() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let alarm = try insertAlarm(in: context, enabled: false)
        let originalTarget = try #require(alarm.stopTargets.first)
        let other = try AlarmRecord(hour: 8, minute: 0, exitPoint: .qrCode, stopTargets: [originalTarget])
        context.insert(other)
        try context.save()
        var draft = AlarmEditorDraft(alarm: alarm, calendar: calendar)
        draft.time = try Date("2026-10-25T09:20:00Z", strategy: .iso8601)
        draft.name = "  Later start  "
        draft.repeatDays = [.saturday, .sunday]
        draft.snoozeEnabled = true
        draft.snoozeMinutes = 20
        draft.exitPoint = .init(selection: .nfc, scannedCode: .init(kind: .nfc, value: "0ABC"))
        var service = makeService(context)
        service.authorize = { Issue.record("Disabled edits must not request permission") }
        service.cancel = { _ in Issue.record("Disabled edits must not cancel schedules") }
        service.schedule = { _, _, _ in Issue.record("Disabled edits must not schedule") }

        try await service.update(draft, alarm: alarm)

        let savedContext = ModelContext(container)
        let records = try savedContext.fetch(FetchDescriptor<AlarmRecord>())
        #expect(records.count == 2)
        let saved = try #require(records.first { $0.id == alarm.id })
        #expect(!saved.isEnabled && saved.label == "Later start")
        #expect(saved.hour == 9 && saved.minute == 20)
        #expect(saved.repeatDays == [.saturday, .sunday])
        #expect(saved.snoozeEnabled && saved.snoozeDurationMinutes == 20)
        #expect(saved.soundName == "birdsong.caf")
        #expect(saved.exitPoint == .nfc && saved.stopTargets.first?.codeValue == "0ABC")
        #expect(saved.stopTargets.first?.alarms.map(\.id) == [alarm.id])
        #expect(originalTarget.alarms.map(\.id) == [other.id])
        #expect(other.acceptsScan(codeValue: "https://example.com/Wake\n", kind: .qrCode))
    }

    @Test func unchangedScanTargetIsReusedAndCanBeRemovedWithoutDeletingOtherAlarmsTargets() async throws {
        let container = try makeContainer()
        let alarm = try insertAlarm(in: container.mainContext, enabled: false)
        let targetID = try #require(alarm.stopTargets.first?.id)
        var draft = AlarmEditorDraft(alarm: alarm, calendar: calendar)
        draft.name = "Renamed"
        let service = makeService(container.mainContext)
        try await service.update(draft, alarm: alarm)
        #expect(alarm.stopTargets.first?.id == targetID)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<AlarmStopTarget>()) == 1)

        draft.exitPoint.select(.normal)
        try await service.update(draft, alarm: alarm)
        let saved = try #require(ModelContext(container).fetch(FetchDescriptor<AlarmRecord>()).first)
        #expect(saved.exitPoint == .normal && saved.stopTargets.isEmpty)
    }

    @Test func enabledEditReplacesOneScheduleUsingTheSameIdentityAndANewToken() async throws {
        let container = try makeContainer()
        let alarm = try insertAlarm(in: container.mainContext)
        var draft = AlarmEditorDraft(alarm: alarm, calendar: calendar)
        draft.name = "Updated"
        draft.time = try Date("2026-10-25T10:15:00Z", strategy: .iso8601)
        var schedules = [alarm.id: "Early start"]
        var operations: [String] = []
        var service = makeService(container.mainContext)
        service.cancel = { id in
            operations.append("cancel")
            schedules[id] = nil
        }
        service.schedule = { record, id, _ in
            #expect(id == alarm.id && record.id == alarm.id)
            #expect(schedules.isEmpty)
            #expect(record.hour == 10 && record.minute == 15)
            #expect(record.scheduleToken != "old-token")
            let saved = try #require(ModelContext(container).fetch(FetchDescriptor<AlarmRecord>()).first)
            #expect(saved.scheduleToken == record.scheduleToken)
            operations.append("schedule")
            schedules[id] = record.label
        }

        try await service.update(draft, alarm: alarm)

        #expect(operations == ["cancel", "schedule"])
        #expect(schedules == [alarm.id: "Updated"])
        #expect(alarm.isEnabled)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<AlarmRecord>()) == 1)
        let runtime = AlarmRuntime(context: container.mainContext)
        try await runtime.handleStop(alarmID: alarm.id.uuidString, systemID: alarm.id.uuidString, token: "old-token")
        #expect(alarm.pendingSince == nil)
    }

    @Test func failedSchedulingRestoresThePreviousRecordTargetsAndSchedule() async throws {
        let container = try makeContainer()
        let alarm = try insertAlarm(in: container.mainContext)
        let targetID = try #require(alarm.stopTargets.first?.id)
        var draft = AlarmEditorDraft(alarm: alarm, calendar: calendar)
        draft.name = "Updated"
        draft.exitPoint = .init(selection: .nfc, scannedCode: .init(kind: .nfc, value: "0ABC"))
        var schedules = [alarm.id: "Early start"]
        var attempts = 0
        var service = makeService(container.mainContext)
        service.cancel = { schedules[$0] = nil }
        service.schedule = { record, id, _ in
            attempts += 1
            if attempts == 1 { throw CocoaError(.featureUnsupported) }
            #expect(record.scheduleToken == "old-token")
            #expect(record.stopTargets.first?.id == targetID)
            schedules[id] = record.label
        }

        await #expect(throws: CocoaError.self) { try await service.update(draft, alarm: alarm) }

        #expect(attempts == 2 && schedules == [alarm.id: "Early start"])
        let savedContext = ModelContext(container)
        let saved = try #require(savedContext.fetch(FetchDescriptor<AlarmRecord>()).first)
        #expect(saved.label == "Early start" && saved.scheduleToken == "old-token")
        #expect(saved.exitPoint == .qrCode && saved.exitPointName == "Kitchen")
        #expect(saved.stopTargets.first?.id == targetID)
        #expect(try savedContext.fetchCount(FetchDescriptor<AlarmStopTarget>()) == 1)
    }

    @Test func failedPersistenceRestoresTheRecordBeforeTouchingTheSystemSchedule() async throws {
        let container = try makeContainer()
        let alarm = try insertAlarm(in: container.mainContext)
        var draft = AlarmEditorDraft(alarm: alarm, calendar: calendar)
        draft.name = "Unsaved"
        var attempts = 0
        var service = makeService(container.mainContext)
        service.save = { context in
            attempts += 1
            if attempts == 1 { throw CocoaError(.fileWriteNoPermission) }
            try context.save()
        }
        service.cancel = { _ in Issue.record("A failed write must leave the schedule alone") }
        service.schedule = { _, _, _ in Issue.record("A failed write must leave the schedule alone") }

        await #expect(throws: CocoaError.self) { try await service.update(draft, alarm: alarm) }

        #expect(attempts == 2)
        let saved = try #require(ModelContext(container).fetch(FetchDescriptor<AlarmRecord>()).first)
        #expect(alarm.label == "Early start" && saved.label == "Early start")
        #expect(alarm.scheduleToken == "old-token" && saved.scheduleToken == "old-token")
    }

    @Test(arguments: ["pending", "snoozed", "system", "duringAuthorization"])
    func editingCannotBypassAnActiveSession(state: String) async throws {
        let container = try makeContainer()
        let alarm = try insertAlarm(in: container.mainContext)
        var draft = AlarmEditorDraft(alarm: alarm, calendar: calendar)
        draft.exitPoint.select(.normal)
        var service = makeService(container.mainContext)
        if state == "pending" { alarm.pendingSince = .now }
        if state == "snoozed" { alarm.snoozedUntil = .now.addingTimeInterval(60) }
        service.hasActiveSession = { _ in state == "system" }
        service.authorize = {
            if state == "duringAuthorization" { alarm.pendingSince = .now }
        }
        service.save = { _ in Issue.record("An active alarm must remain unchanged") }
        service.cancel = { _ in Issue.record("An active alarm must not be cancelled") }

        await #expect(throws: AlarmRuntime.SessionError.scanRequired) { try await service.update(draft, alarm: alarm) }
        #expect(alarm.exitPoint == .qrCode && alarm.scheduleToken == "old-token")
    }

    @Test func permissionDenialAndInvalidDraftsLeaveTheOldConfigurationUntouched() async throws {
        let container = try makeContainer()
        let alarm = try insertAlarm(in: container.mainContext)
        var service = makeService(container.mainContext)
        service.authorize = { throw CocoaError(.userCancelled) }
        service.save = { _ in Issue.record("Rejected edits must not write") }
        service.cancel = { _ in Issue.record("Rejected edits must not cancel") }
        var draft = AlarmEditorDraft(alarm: alarm, calendar: calendar)
        draft.name = "Unsaved"
        await #expect(throws: CocoaError.self) { try await service.update(draft, alarm: alarm) }
        draft.snoozeMinutes = 0
        await #expect(throws: AlarmValidationError.invalidSnoozeDuration) {
            try await service.update(draft, alarm: alarm)
        }
        #expect(!container.mainContext.hasChanges)
        #expect(alarm.label == "Early start" && alarm.scheduleToken == "old-token")
    }

    @Test(arguments: [true, false])
    func recoveryFailureIsReportedInsteadOfClaimingTheAlarmWasRestored(persistenceFailure: Bool) async throws {
        let container = try makeContainer()
        let alarm = try insertAlarm(in: container.mainContext)
        var service = makeService(container.mainContext)
        if persistenceFailure {
            service.save = { _ in throw CocoaError(.fileWriteNoPermission) }
        } else {
            service.schedule = { _, _, _ in throw CocoaError(.featureUnsupported) }
        }
        var draft = AlarmEditorDraft(alarm: alarm, calendar: calendar)
        draft.name = "Unsaved"

        await #expect(throws: AlarmRecoveryError.self) { try await service.update(draft, alarm: alarm) }
    }
}
