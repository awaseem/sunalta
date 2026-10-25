import Foundation

/// Scan setup stays separate from the saved alarm until the editor is saved.
struct AlarmExitPointDraft: Equatable {

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
