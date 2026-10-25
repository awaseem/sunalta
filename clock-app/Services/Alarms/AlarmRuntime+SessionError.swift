import Foundation

extension AlarmRuntime {
    enum SessionError: LocalizedError {
        case scanRequired, wrongScan, alarmDeleted

        var errorDescription: String? {
            switch self {
            case .scanRequired: "Finish the active alarm before changing it."
            case .wrongScan: "That isn't the exit point for this alarm. Scan the configured code or tag."
            case .alarmDeleted: "This alarm was deleted. Close the editor and create a new alarm."
            }
        }
    }
}
