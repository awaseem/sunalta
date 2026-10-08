import Foundation

/// Scan setup stays in the draft until the user creates the alarm.
struct AlarmExitPointDraft {
    struct ScannedCode: Equatable {
        let kind: AlarmStopTarget.Kind
        let value: String
    }

    var selection: AlarmExitPoint = .normal
    var scannedCode: ScannedCode?

    mutating func select(_ selection: AlarmExitPoint) {
        guard self.selection != selection else { return }
        self = AlarmExitPointDraft(selection: selection)
    }

    func makeStopTarget() throws -> AlarmStopTarget? {
        guard let scannedCode else { return nil }
        guard scannedCode.kind == selection.scanKind else { throw AlarmValidationError.invalidScanTarget }
        return try AlarmStopTarget(name: selection.title, kind: scannedCode.kind, codeValue: scannedCode.value)
    }
}
