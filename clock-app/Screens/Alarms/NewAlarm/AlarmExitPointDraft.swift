import Foundation

/// Scan setup stays in the draft until the user creates the alarm.
struct AlarmExitPointDraft {
    struct ScannedCode: Equatable {
        let kind: AlarmStopTarget.Kind
        let value: String
    }

    var name = ""
    var scannedCode: ScannedCode?
    var savedTarget: AlarmStopTarget?

    var usesAnyScan: Bool { scannedCode == nil && savedTarget == nil }

    func makeStopTarget() throws -> AlarmStopTarget? {
        if let scannedCode {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return try AlarmStopTarget(
                name: trimmedName.isEmpty ? (scannedCode.kind == .nfc ? "NFC tag" : "QR code") : trimmedName,
                kind: scannedCode.kind, codeValue: scannedCode.value
            )
        }
        if let savedTarget { try savedTarget.validate() }
        return savedTarget
    }
}
