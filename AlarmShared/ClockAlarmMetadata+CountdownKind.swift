import Foundation

nonisolated extension ClockAlarmMetadata {
    enum CountdownKind: String, Codable, Sendable {
        case snooze, scanReminder
    }
}
