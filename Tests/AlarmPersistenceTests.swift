import Foundation
import SwiftData
import Testing
@testable import clock_app

@MainActor
struct AlarmPersistenceTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(for: AlarmRecord.self, AlarmStopTarget.self,
                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    @Test func creationPersistsTheAlarmAndItsInverseRelationship() throws {
        let container = try makeContainer()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        var draft = NewAlarmDraft()
        draft.name = " \n Morning workout \t "
        draft.time = try Date("2026-10-08T07:05:00Z", strategy: .iso8601)
        draft.repeatDays = [.monday, .friday]
        draft.exitPoint = .init(selection: .qrCode, scannedCode: .init(kind: .qrCode, value: "wake-up"))
        let created = try AlarmCreationService(context: container.mainContext, calendar: calendar).create(draft)

        // Fetch from an independent context to verify an explicit save, not an in-memory insertion.
        let context = ModelContext(container)
        let alarm = try #require(context.fetch(FetchDescriptor<AlarmRecord>()).first)
        let target = try #require(context.fetch(FetchDescriptor<AlarmStopTarget>()).first)
        #expect(alarm.id == created.id)
        #expect(alarm.label == "Morning workout")
        #expect(alarm.hour == 7 && alarm.minute == 5 && !alarm.isEnabled)
        #expect(alarm.repeatDays == [.monday, .friday])
        #expect(alarm.stopTargets.map(\.id) == [target.id])
        #expect(target.alarms.map(\.id) == [alarm.id])
    }

    @Test(arguments: [("", ""), (" \t\n\r ", ""), ("\u{00A0}\u{2003}", ""), (" Alarm ", "Alarm")])
    func creationKeepsUnnamedAlarmsDistinctFromAnExplicitAlarmName(name: String, expectedLabel: String) throws {
        let container = try makeContainer()
        var draft = NewAlarmDraft()
        draft.name = name
        try AlarmCreationService(context: container.mainContext).create(draft)

        let context = ModelContext(container)
        let alarm = try #require(context.fetch(FetchDescriptor<AlarmRecord>()).first)
        #expect(alarm.label == expectedLabel)
    }

    @Test func invalidCreationDoesNotInsertPartialRecords() throws {
        let container = try makeContainer()
        var draft = NewAlarmDraft()
        draft.exitPoint = .init(selection: .qrCode, scannedCode: .init(kind: .nfc, value: "0ABC"))
        #expect(throws: AlarmValidationError.invalidScanTarget) {
            try AlarmCreationService(context: container.mainContext).create(draft)
        }
        #expect(try container.mainContext.fetchCount(FetchDescriptor<AlarmRecord>()) == 0)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<AlarmStopTarget>()) == 0)
    }

    @Test func deletingATargetNullifiesTheAlarmRelationship() throws {
        let container = try makeContainer()
        var draft = NewAlarmDraft()
        draft.exitPoint = .init(selection: .nfc, scannedCode: .init(kind: .nfc, value: "0ABC"))
        let alarm = try AlarmCreationService(context: container.mainContext).create(draft)
        let target = try #require(alarm.stopTargets.first)
        container.mainContext.delete(target)
        try container.mainContext.save()
        #expect(alarm.stopTargets.isEmpty)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<AlarmRecord>()) == 1)
    }

    @Test func runtimesUseTheirInjectedContexts() async throws {
        let first = try makeContainer()
        let second = try makeContainer()
        var draft = NewAlarmDraft()
        draft.exitPoint.selection = .qrCode
        let alarm = try AlarmCreationService(context: first.mainContext).create(draft)
        let secondRuntime = AlarmRuntime(context: second.mainContext)
        // An unknown alarm ID must remain a harmless no-op in a separate store.
        try await secondRuntime.handleStop(alarmID: alarm.id.uuidString,
                                           systemID: alarm.id.uuidString, token: "")
        #expect(secondRuntime.activeAlarm == nil)
        #expect(try second.mainContext.fetchCount(FetchDescriptor<AlarmRecord>()) == 0)
        #expect(try first.mainContext.fetchCount(FetchDescriptor<AlarmRecord>()) == 1)
        #expect(alarm.exitPoint == .qrCode)
    }
}
