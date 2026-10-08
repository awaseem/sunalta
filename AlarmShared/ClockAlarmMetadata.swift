import AlarmKit
import Foundation

nonisolated struct ClockAlarmMetadata: AlarmMetadata {
    enum CountdownKind: String, Codable, Sendable {
        case snooze, scanReminder
    }

    let alarmID: UUID
    let token: String
    let title: String
    let scanSymbol: String?
    let countdownKind: CountdownKind

    var actionTitle: String {
        switch scanSymbol {
        case "wave.3.right": "Scan NFC"
        case .some: "Scan QR"
        case nil: "Stop"
        }
    }
}
