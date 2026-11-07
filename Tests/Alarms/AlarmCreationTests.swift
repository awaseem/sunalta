import AlarmKit
import Foundation
import SwiftData
import Testing

@testable import Sunalta

@MainActor
struct AlarmCreationTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: AlarmRecord.self, AlarmStopTarget.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    @Test func creationAuthorizesAndSchedulesBeforeReturningAnEnabledAlarm() async throws {
        let container = try makeContainer()
        var operations: [String] = []
        var scheduledIDs: [UUID] = []
        let system = AlarmRuntimeSystem(
            authorize: {
                operations.append("authorize")
            },
            schedule: { alarm, id, _ in
                operations.append("schedule")
                scheduledIDs.append(id)
                let saved = try #require(
                    ModelContext(container).fetch(FetchDescriptor<AlarmRecord>()).first)
                #expect(saved.id == id && id == alarm.id)
                #expect(saved.scheduleToken != nil && saved.scheduleToken == alarm.scheduleToken)
                #expect(saved.configurationVersion == AlarmRuntime.configurationVersion)
            })
        let runtime = AlarmRuntime(context: container.mainContext, system: system)

        let created = try await runtime.create(from: AlarmEditorDraft())

        let saved = try #require(
            ModelContext(container).fetch(FetchDescriptor<AlarmRecord>()).first)
        #expect(operations == ["authorize", "schedule"])
        #expect(scheduledIDs == [created.id])
        #expect(created.isEnabled && saved.isEnabled)
    }

    @Test(arguments: [true, false])
    func failedCreationCanBeRetriedWithoutDuplicateAlarmsOrScanTargets(permissionDenied: Bool)
        async throws
    {
        let container = try makeContainer()
        let context = container.mainContext
        let existing = try AlarmEditorService(context: context).create(AlarmEditorDraft())
        var draft = AlarmEditorDraft()
        draft.exitPoint = .init(
            selection: .qrCode, scannedCode: .init(kind: .qrCode, value: "wake-up"))
        var authorizationAttempts = 0
        var schedulingAttempts = 0
        var scheduledIDs: [UUID] = []
        let system = AlarmRuntimeSystem(
            authorize: {
                authorizationAttempts += 1
                if authorizationAttempts == 1 && permissionDenied {
                    throw AlarmScheduler.SchedulingError.permissionDenied
                }
            },
            schedule: { _, id, _ in
                schedulingAttempts += 1
                if schedulingAttempts == 1 && !permissionDenied {
                    throw CocoaError(.featureUnsupported)
                }
                scheduledIDs.append(id)
            })
        let runtime = AlarmRuntime(
            context: context, system: system,
            cancelAlarm: { _ in
                Issue.record("A rejected creation has no schedule to cancel")
            })

        if permissionDenied {
            await #expect(throws: AlarmScheduler.SchedulingError.permissionDenied) {
                _ = try await runtime.create(from: draft)
            }
        } else {
            await #expect(throws: CocoaError.self) { _ = try await runtime.create(from: draft) }
        }

        let failedContext = ModelContext(container)
        #expect(try failedContext.fetch(FetchDescriptor<AlarmRecord>()).map(\.id) == [existing.id])
        #expect(try failedContext.fetchCount(FetchDescriptor<AlarmStopTarget>()) == 0)
        #expect(scheduledIDs.isEmpty)

        let created = try await runtime.create(from: draft)

        let savedContext = ModelContext(container)
        let alarms = try savedContext.fetch(FetchDescriptor<AlarmRecord>())
        #expect(alarms.count == 2)
        #expect(alarms.first { $0.id == created.id }?.isEnabled == true)
        #expect(scheduledIDs == [created.id])
        let target = try #require(savedContext.fetch(FetchDescriptor<AlarmStopTarget>()).first)
        #expect(target.alarms.map(\.id) == [created.id])
        #expect(try savedContext.fetchCount(FetchDescriptor<AlarmStopTarget>()) == 1)
    }

    @Test func cancellationDuringAuthorizationDoesNotScheduleOrKeepANewAlarm() async throws {
        let container = try makeContainer()
        let system = AlarmRuntimeSystem(
            authorize: {
                withUnsafeCurrentTask { $0?.cancel() }
            },
            schedule: { _, _, _ in
                Issue.record("A cancelled creation must not schedule an alarm")
            })
        let runtime = AlarmRuntime(context: container.mainContext, system: system)

        await #expect(throws: CancellationError.self) {
            _ = try await runtime.create(from: AlarmEditorDraft())
        }

        #expect(try ModelContext(container).fetchCount(FetchDescriptor<AlarmRecord>()) == 0)
    }
}
