import Foundation

extension AlarmExitPointDraft {
    struct ScannedCode: Equatable {
        let kind: AlarmStopTarget.Kind
        let value: String
    }
}
