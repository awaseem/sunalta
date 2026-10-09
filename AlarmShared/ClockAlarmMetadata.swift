import AlarmKit
import Foundation

nonisolated struct ClockAlarmMetadata: AlarmMetadata {

    let alarmID: UUID
    let token: String
    let title: String
    let scanSymbol: String?
    let countdownKind: CountdownKind

    var statusText: String {
        countdownKind == .scanReminder ? "Scan to end the alarm" : "Snoozed"
    }

    var actionTitle: String {
        switch scanSymbol {
        case "wave.3.right": "Scan NFC"
        case .some: "Scan QR"
        case nil: "Stop"
        }
    }
}
