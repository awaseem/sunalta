import Foundation
import SwiftData

enum AlarmValidationError: Error, Equatable {
    case invalidTime
    case invalidSnoozeDuration
    case invalidSoundName
    case invalidScanTarget
}

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
    var requiresScanToStop: Bool
    var exitPointName: String? = nil
    @Relationship(deleteRule: .nullify, inverse: \AlarmStopTarget.alarms)
    var stopTargets: [AlarmStopTarget]

    init(
        hour: Int, minute: Int, label: String = "Alarm", isEnabled: Bool = true,
        repeatDays: Set<ClockWeekday> = [], soundName: String? = nil,
        snoozeEnabled: Bool = true, snoozeDurationMinutes: Int = 9,
        requiresScanToStop: Bool = false, stopTargets: [AlarmStopTarget] = [],
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
        self.requiresScanToStop = requiresScanToStop
        self.stopTargets = stopTargets
        let trimmedName = exitPointName?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.exitPointName = trimmedName?.isEmpty == false ? trimmedName : nil
        try validate()
    }

    var repeatDays: Set<ClockWeekday> {
        get { Set(repeatDayValues.compactMap(ClockWeekday.init(rawValue:))) }
        set { repeatDayValues = newValue.map(\.rawValue).sorted() }
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
        // An empty target list means any QR code or NFC tag can stop the alarm.
        for target in stopTargets { try target.validate() }
    }

    func acceptsScan(codeValue: String, kind: AlarmStopTarget.Kind) -> Bool {
        guard requiresScanToStop, AlarmStopTarget.isValidScan(codeValue: codeValue, kind: kind) else {
            return false
        }
        return stopTargets.isEmpty || stopTargets.contains { $0.matches(codeValue: codeValue, kind: kind) }
    }

    var exitPointSummary: String {
        let scanDescription = stopTargets.isEmpty ? "Any QR code or NFC tag" : "Scan to stop"
        let name = exitPointName ?? stopTargets.first?.name
        guard let name, !name.isEmpty else { return scanDescription }
        return "\(name) · \(scanDescription)"
    }
}
