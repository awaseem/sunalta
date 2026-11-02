import AlarmKit
import Foundation
import SwiftData
import Testing
@testable import Sunalta

@MainActor
struct AlarmSessionTests {
    private func fixture(exitPoint: AlarmExitPoint = .normal) throws
        -> (ModelContainer, AlarmRecord, AlarmSessionSystem, AlarmRuntime) {
        let container = try ModelContainer(for: AlarmRecord.self, AlarmStopTarget.self,
                                            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let alarm = try AlarmRecord(hour: 7, minute: 0, exitPoint: exitPoint)
        alarm.configurationVersion = AlarmRuntime.configurationVersion
        container.mainContext.insert(alarm)
        try container.mainContext.save()
        let system = AlarmSessionSystem()
        system.states[alarm.id] = .alerting
        let runtime = AlarmRuntime(context: container.mainContext, system: system.operations,
                                   cancelAlarm: { system.states[$0] = nil })
        return (container, alarm, system, runtime)
    }

    @Test(arguments: [AlarmExitPoint.normal, .qrCode, .nfc])
    func snoozeKeepsTheScreenAndPersistedSessionAlive(exitPoint: AlarmExitPoint) async throws {
        let (container, alarm, _, runtime) = try fixture(exitPoint: exitPoint)
        defer { withExtendedLifetime(container) {} }
        await runtime.refresh()
        let started = try #require(alarm.pendingSince)
        try await runtime.snooze(alarm)
        let deadline = try #require(alarm.snoozedUntil)
        await runtime.refresh()

        #expect(runtime.activeAlarm?.id == alarm.id && runtime.isAlarmPresented)
        #expect(alarm.pendingSince == started && alarm.snoozedUntil == deadline)
        let savedContext = ModelContext(container)
        let saved = try #require(savedContext.fetch(FetchDescriptor<AlarmRecord>()).first)
        #expect(saved.pendingSince == started && saved.snoozedUntil == deadline)

        // A duplicate intent or tap must not extend the existing snooze.
        try await runtime.snooze(alarm)
        #expect(alarm.snoozedUntil == deadline)
    }

    @Test func hidingAndReopeningDoesNotStopOrRestartTheAlarm() async throws {
        let (container, alarm, system, runtime) = try fixture()
        defer { withExtendedLifetime(container) {} }
        await runtime.refresh()
        runtime.hideActiveAlarm()
        await runtime.refresh()
        #expect(!runtime.isAlarmPresented && runtime.activeAlarm?.id == alarm.id)
        #expect(system.states[alarm.id] == .alerting)
        runtime.presentActiveAlarm()
        try await runtime.snooze(alarm)
        let deadline = alarm.snoozedUntil
        runtime.hideActiveAlarm()
        await runtime.refresh()
        #expect(!runtime.isAlarmPresented && runtime.activeAlarm?.id == alarm.id)
        runtime.presentActiveAlarm()
        #expect(runtime.isAlarmPresented && alarm.snoozedUntil == deadline)

        runtime.hideActiveAlarm()
        system.states[alarm.id] = .alerting
        await runtime.refresh()
        #expect(runtime.isAlarmPresented && alarm.snoozedUntil == nil)
    }

    @Test func snoozedSessionReturnsAfterRelaunchWithoutExtendingItsDeadline() async throws {
        let (container, alarm, system, runtime) = try fixture()
        defer { withExtendedLifetime(container) {} }
        await runtime.refresh()
        try await runtime.snooze(alarm)
        let deadline = alarm.snoozedUntil
        let reloaded = AlarmRuntime(context: ModelContext(container), system: system.operations,
                                    cancelAlarm: { system.states[$0] = nil })
        await reloaded.refresh()
        #expect(reloaded.activeAlarm?.id == alarm.id && reloaded.isAlarmPresented)
        #expect(reloaded.activeAlarm?.snoozedUntil == deadline)
    }

    @Test func systemSnoozeRestoresAnOlderSessionWithNoPendingFlag() async throws {
        let (container, alarm, system, runtime) = try fixture()
        defer { withExtendedLifetime(container) {} }
        alarm.snoozedUntil = .now.addingTimeInterval(60)
        system.states[alarm.id] = .countdown
        await runtime.refresh()
        #expect(alarm.pendingSince != nil && runtime.activeAlarm?.id == alarm.id)
        #expect(runtime.isAlarmPresented)
    }

    @Test(arguments: [AlarmExitPoint.normal, .qrCode, .nfc])
    func stoppingDuringSnoozeClearsTheSessionAndAllOwnedCountdowns(exitPoint: AlarmExitPoint) async throws {
        let (container, alarm, system, runtime) = try fixture(exitPoint: exitPoint)
        defer { withExtendedLifetime(container) {} }
        await runtime.refresh()
        try await runtime.snooze(alarm)
        if exitPoint != .normal {
            await #expect(throws: AlarmRuntime.SessionError.wrongScan) { try await runtime.finish(alarm) }
            #expect(runtime.activeAlarm?.id == alarm.id)
        }
        try await runtime.finish(alarm, code: exitPoint == .nfc ? "0ABC" : "wake-up", kind: exitPoint.scanKind)
        #expect(runtime.activeAlarm == nil && !runtime.isAlarmPresented)
        #expect(system.states.isEmpty && alarm.retryAlarmIDs.isEmpty)
        let savedContext = ModelContext(container)
        let saved = try #require(savedContext.fetch(FetchDescriptor<AlarmRecord>()).first)
        #expect(saved.pendingSince == nil && saved.snoozedUntil == nil && !saved.isEnabled)
    }

    @Test func stoppingASnoozedRepeatingAlarmPreservesItsNextOccurrence() async throws {
        let (container, alarm, system, runtime) = try fixture()
        defer { withExtendedLifetime(container) {} }
        alarm.repeatDays = [.monday]
        system.recurringIDs.insert(alarm.id)
        await runtime.refresh()
        try await runtime.snooze(alarm)
        try await runtime.finish(alarm)
        #expect(runtime.activeAlarm == nil && alarm.isEnabled)
        #expect(system.states[alarm.id] == .scheduled && alarm.pendingSince == nil)
    }

    @Test func aSystemStopRemovesTheSnoozedIsland() async throws {
        let (container, alarm, system, runtime) = try fixture()
        defer { withExtendedLifetime(container) {} }
        await runtime.refresh()
        try await runtime.snooze(alarm)
        runtime.hideActiveAlarm()
        system.states[alarm.id] = nil
        await runtime.refresh()
        #expect(runtime.activeAlarm == nil && !runtime.isAlarmPresented)
        #expect(alarm.snoozedUntil == nil && alarm.pendingSince == nil)
    }

    @Test func anotherRingingAlarmTakesPriorityWithoutLosingTheSnoozedAlarm() async throws {
        let (container, alarm, system, runtime) = try fixture()
        defer { withExtendedLifetime(container) {} }
        await runtime.refresh()
        try await runtime.snooze(alarm)
        runtime.hideActiveAlarm()
        let other = try AlarmRecord(hour: 7, minute: 1)
        container.mainContext.insert(other)
        system.states[other.id] = .alerting
        await runtime.refresh()
        #expect(runtime.activeAlarm?.id == other.id && runtime.isAlarmPresented)
        try await runtime.finish(other)
        #expect(runtime.activeAlarm?.id == alarm.id && runtime.isAlarmPresented)
        #expect(alarm.snoozedUntil != nil)
    }

    @Test func failedSnoozeKeepsTheRingingScreenUsable() async throws {
        let (container, alarm, system, runtime) = try fixture()
        defer { withExtendedLifetime(container) {} }
        await runtime.refresh()
        system.snoozeFails = true
        await #expect(throws: CocoaError.self) { try await runtime.snooze(alarm) }
        #expect(runtime.activeAlarm?.id == alarm.id && runtime.isAlarmPresented)
        #expect(alarm.snoozedUntil == nil && system.states[alarm.id] == .alerting)
    }
}
