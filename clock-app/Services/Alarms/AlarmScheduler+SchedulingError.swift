import Foundation

extension AlarmScheduler {
    enum SchedulingError: LocalizedError {
        case permissionDenied

        var errorDescription: String? {
            "Allow alarms for Clock in Settings before turning this alarm on."
        }
    }
}
