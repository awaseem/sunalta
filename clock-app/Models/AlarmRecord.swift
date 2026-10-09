import Foundation
import SwiftData

@Model
final class AlarmRecord {
    @Attribute(.unique) private(set) var id: UUID
    var label: String
    var isEnabled: Bool
    private(set) var hour: Int
    private(set) var minute: Int
    private var repeatDayValues: [Int]
    var soundName: String?
    var snoozeEnabled: Bool
    private(set) var snoozeDurationMinutes: Int
    private var requiresScanToStop: Bool
    private var exitPointValue: String? = nil
    var exitPointName: String? = nil
    // The wake-up session survives system Stop and an app restart.
    var scheduleToken: String? = nil
    var lastCompletedAt: Date? = nil
    var pendingSince: Date? = nil
    var retryAlarmIDs: [UUID] = []
    var nextRetryAt: Date? = nil
    var snoozedUntil: Date? = nil
    var configurationVersion: Int? = nil
    @Relationship(deleteRule: .nullify, inverse: \AlarmStopTarget.alarms)
    var stopTargets: [AlarmStopTarget]

    init(
        hour: Int, minute: Int, label: String = "Alarm", isEnabled: Bool = true,
        repeatDays: Set<ClockWeekday> = [], soundName: String? = nil,
        snoozeEnabled: Bool = true, snoozeDurationMinutes: Int = 9,
        exitPoint: AlarmExitPoint = .normal, stopTargets: [AlarmStopTarget] = [],
        exitPointName: String? = nil
    ) throws {
        self.id = UUID()
        self.hour = hour
        self.minute = minute
        self.label = label
        self.isEnabled = isEnabled
        self.repeatDayValues = repeatDays.map(\.rawValue).sorted()
        self.soundName = soundName
        self.snoozeEnabled = snoozeEnabled
        self.snoozeDurationMinutes = snoozeDurationMinutes
        self.requiresScanToStop = exitPoint != .normal
        self.exitPointValue = exitPoint.rawValue
        self.stopTargets = stopTargets
        let trimmedName = exitPointName?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.exitPointName = trimmedName?.isEmpty == false ? trimmedName : nil
        try validate()
    }

    var repeatDays: Set<ClockWeekday> {
        get { Set(repeatDayValues.compactMap(ClockWeekday.init(rawValue:))) }
        set { repeatDayValues = newValue.map(\.rawValue).sorted() }
    }

    var exitPoint: AlarmExitPoint {
        if let exitPointValue, let selection = AlarmExitPoint(rawValue: exitPointValue) {
            return selection
        }
        // Older alarms didn't store a method. Preserve configured scan targets;
        // alarms without a target use the new Normal default.
        guard requiresScanToStop else { return .normal }
        switch stopTargets.first?.kind {
        case .nfc: return .nfc
        case .qrCode: return .qrCode
        case nil: return .normal
        }
    }

    func setTime(hour: Int, minute: Int) throws {
        guard (0...23).contains(hour), (0...59).contains(minute) else {
            throw AlarmValidationError.invalidTime
        }
        self.hour = hour
        self.minute = minute
    }

    func setSnoozeDuration(minutes: Int) throws {
        guard minutes > 0 else { throw AlarmValidationError.invalidSnoozeDuration }
        snoozeDurationMinutes = minutes
    }

    func validate() throws {
        guard (0...23).contains(hour), (0...59).contains(minute) else {
            throw AlarmValidationError.invalidTime
        }
        guard snoozeDurationMinutes > 0 else { throw AlarmValidationError.invalidSnoozeDuration }
        if let soundName, soundName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw AlarmValidationError.invalidSoundName
        }
        guard stopTargets.count <= 1 else { throw AlarmValidationError.invalidScanTarget }
        for target in stopTargets {
            try target.validate()
            guard target.kind == exitPoint.scanKind else { throw AlarmValidationError.invalidScanTarget }
        }
    }

    func acceptsScan(codeValue: String, kind: AlarmStopTarget.Kind) -> Bool {
        guard exitPoint.scanKind == kind, AlarmStopTarget.isValidScan(codeValue: codeValue, kind: kind) else {
            return false
        }
        return stopTargets.isEmpty || stopTargets.contains { $0.matches(codeValue: codeValue, kind: kind) }
    }

    var exitPointSummary: String {
        switch exitPoint {
        case .normal: "Normal stop button"
        case .nfc: stopTargets.isEmpty ? "Any NFC tag" : "Specific NFC tag"
        case .qrCode: stopTargets.isEmpty ? "Any QR code" : "Specific QR code"
        }
    }

    func latestOccurrence(before date: Date = .now, calendar: Calendar = .autoupdatingCurrent) -> Date? {
        AlarmOccurrence.latest(hour: hour, minute: minute, repeatDays: repeatDays,
                               before: date, calendar: calendar)
    }
}
