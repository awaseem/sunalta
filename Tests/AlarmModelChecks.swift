import Foundation
import SwiftData

@main
struct AlarmModelChecks {
    @MainActor
    static func main() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let schema = Schema([AlarmRecord.self, AlarmStopTarget.self])
        let configuration = ModelConfiguration(schema: schema, url: folder.appendingPathComponent("alarms.store"))
        let alarmID: UUID
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            let context = ModelContext(container)
            let nfc = try AlarmStopTarget(name: "Bathroom", kind: .nfc, codeValue: AlarmStopTarget.nfcIdentifier(from: Data([0, 1, 255])))
            let qr = try AlarmStopTarget(name: "Kitchen", kind: .qrCode, codeValue: "Wake Up ")
            let barcode = try AlarmStopTarget(name: "Coffee", kind: .qrCode, codeValue: "001234")
            let alarm = try AlarmRecord(hour: 16, minute: 9, label: "Wake up", repeatDays: [.monday, .friday],
                                        soundName: "bell.caf", requiresScanToStop: true, stopTargets: [nfc, qr, barcode])
            let other = try AlarmRecord(hour: 7, minute: 0, requiresScanToStop: true, stopTargets: [qr])
            alarmID = alarm.id
            context.insert(alarm)
            context.insert(other)
            try context.save()
            precondition(nfc.codeValue == "0001FF")
            precondition(alarm.acceptsScan(codeValue: "0001FF", kind: .nfc))
            precondition(!alarm.acceptsScan(codeValue: "01FF", kind: .nfc))
            precondition(alarm.acceptsScan(codeValue: "Wake Up ", kind: .qrCode))
            precondition(alarm.acceptsScan(codeValue: "Wake Up", kind: .qrCode))
            precondition(!alarm.acceptsScan(codeValue: "wake up", kind: .qrCode))
            precondition(alarm.acceptsScan(codeValue: "001234", kind: .qrCode))
            precondition(!alarm.acceptsScan(codeValue: "1234", kind: .qrCode))
            precondition(!alarm.acceptsScan(codeValue: "001234", kind: .nfc))
            let url = try AlarmStopTarget(name: "URL", kind: .qrCode, codeValue: " HTTPS://EXAMPLE.COM/ ")
            precondition(url.codeValue == "https://example.com")
            precondition(url.matches(codeValue: "https://example.com", kind: .qrCode))
            precondition(!url.matches(codeValue: "https://example.com/path", kind: .qrCode))
            expect(.invalidScanTarget) { _ = try AlarmStopTarget(name: "Empty", kind: .qrCode, codeValue: " ") }
            expect(.invalidTime) { _ = try AlarmRecord(hour: 24, minute: 0) }
            expect(.invalidTime) { try alarm.setTime(hour: 3, minute: -1) }
            precondition(alarm.hour == 16 && alarm.minute == 9)
            expect(.invalidSnoozeDuration) { try alarm.setSnoozeDuration(minutes: 0) }
            expect(.missingStopTarget) { _ = try AlarmRecord(hour: 1, minute: 0, requiresScanToStop: true) }
            expect(.invalidScanTarget) { _ = try AlarmStopTarget(name: "Empty", kind: .nfc, codeValue: "  ") }
        }
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            let context = ModelContext(container)
            let alarms = try context.fetch(FetchDescriptor<AlarmRecord>())
            let alarm = alarms.first { $0.id == alarmID }!
            precondition(alarms.count == 2 && alarm.stopTargets.count == 3)
            precondition(alarm.hour == 16 && alarm.minute == 9 && alarm.label == "Wake up")
            precondition(alarm.repeatDays == [.monday, .friday])
            precondition(alarm.snoozeEnabled && alarm.snoozeDurationMinutes == 9 && alarm.soundName == "bell.caf")
            let qr = alarm.stopTargets.first { $0.codeValue == "Wake Up" }!
            precondition(qr.alarms.count == 2)
            context.delete(alarm)
            try context.save()
            let targetCount = try context.fetchCount(FetchDescriptor<AlarmStopTarget>())
            precondition(targetCount == 3)
            let remaining = try context.fetch(FetchDescriptor<AlarmRecord>()).first!
            context.delete(qr)
            try context.save()
            precondition(remaining.stopTargets.isEmpty && remaining.requiresScanToStop)
            precondition(!remaining.acceptsScan(codeValue: "Wake Up ", kind: .qrCode))
            expect(.missingStopTarget) { try remaining.validate() }
        }
        print("PASS: persistence, shared relationships, deletion, validation, and Foqos-compatible scan matching")
    }

    @MainActor
    static func expect(_ expected: AlarmValidationError, operation: () throws -> Void) {
        do {
            try operation()
            preconditionFailure("Expected \(expected)")
        } catch {
            precondition(error as? AlarmValidationError == expected, "Unexpected error: \(error)")
        }
    }
}
