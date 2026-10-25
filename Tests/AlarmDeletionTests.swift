import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import clock_app

@MainActor
struct AlarmDeletionTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(for: AlarmRecord.self, AlarmStopTarget.self,
                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    @Test func deletionCancelsAllSchedulesAndPreservesSharedScanTargets() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let target = try AlarmStopTarget(name: "Kitchen", kind: .qrCode, codeValue: "wake-up")
        let alarm = try AlarmRecord(hour: 7, minute: 0, exitPoint: .qrCode, stopTargets: [target])
        let otherAlarm = try AlarmRecord(hour: 8, minute: 0, exitPoint: .qrCode, stopTargets: [target])
        alarm.retryAlarmIDs = [UUID(), UUID()]
        context.insert(alarm)
        context.insert(otherAlarm)
        try context.save()
        let expectedIDs = [alarm.id] + alarm.retryAlarmIDs
        let remainingID = otherAlarm.id
        var cancelledIDs: [UUID] = []
        let runtime = AlarmRuntime(context: context) { id in
            // Persistence must still track the alarm until every cancellation succeeds.
            let savedAlarmCount = try context.fetchCount(FetchDescriptor<AlarmRecord>())
            #expect(savedAlarmCount == 2)
            cancelledIDs.append(id)
        }

        try await runtime.delete(alarm)

        #expect(cancelledIDs == expectedIDs)
        let savedContext = ModelContext(container)
        #expect(try savedContext.fetch(FetchDescriptor<AlarmRecord>()).map(\.id) == [remainingID])
        let savedTarget = try #require(savedContext.fetch(FetchDescriptor<AlarmStopTarget>()).first)
        #expect(savedTarget.alarms.map(\.id) == [remainingID])
    }

    @Test(arguments: [0, 1, 2])
    func failedCancellationKeepsAlarmAndRetryOwnership(failureIndex: Int) async throws {
        let container = try makeContainer()
        let alarm = try AlarmRecord(hour: 7, minute: 0)
        alarm.retryAlarmIDs = [UUID(), UUID()]
        container.mainContext.insert(alarm)
        try container.mainContext.save()
        let expectedIDs = [alarm.id] + alarm.retryAlarmIDs
        let runtime = AlarmRuntime(context: container.mainContext) { id in
            if id == expectedIDs[failureIndex] { throw CocoaError(.fileWriteNoPermission) }
        }

        await #expect(throws: CocoaError.self) { try await runtime.delete(alarm) }

        let savedContext = ModelContext(container)
        let savedAlarm = try #require(savedContext.fetch(FetchDescriptor<AlarmRecord>()).first)
        #expect([savedAlarm.id] + savedAlarm.retryAlarmIDs == expectedIDs)
        #expect(!alarm.isDeleted)
    }

    @Test func deletionCannotBypassAPendingScan() async throws {
        let container = try makeContainer()
        let alarm = try AlarmRecord(hour: 7, minute: 0, exitPoint: .qrCode)
        alarm.pendingSince = .now
        container.mainContext.insert(alarm)
        try container.mainContext.save()
        var cancelledIDs: [UUID] = []
        let runtime = AlarmRuntime(context: container.mainContext) { cancelledIDs.append($0) }

        await #expect(throws: AlarmRuntime.SessionError.scanRequired) { try await runtime.delete(alarm) }

        #expect(cancelledIDs.isEmpty)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<AlarmRecord>()) == 1)
    }

    @Test func aRetainedRowCanRenderAfterItsAlarmHasBeenDeleted() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let target = try AlarmStopTarget(name: "Kitchen", kind: .qrCode, codeValue: "wake-up")
        let alarm = try AlarmRecord(hour: 7, minute: 0, repeatDays: [.tuesday, .thursday],
                                   exitPoint: .qrCode, stopTargets: [target])
        context.insert(alarm)
        try context.save()
        let row = AlarmRow(alarm: alarm, onEdit: {})

        try await AlarmRuntime(context: context, cancelAlarm: { _ in }).delete(alarm)
        #expect(alarm.modelContext == nil)

        // The swipe animation can request another render after the record is detached.
        let renderer = ImageRenderer(content: row.appTheme(.white).frame(width: 360))
        #expect(renderer.cgImage != nil)
    }
}
