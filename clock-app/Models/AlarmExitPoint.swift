import Foundation

enum AlarmExitPoint: String, CaseIterable, Identifiable {
    case normal, nfc, qrCode

    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal: "Normal"
        case .nfc: "NFC tag"
        case .qrCode: "QR code"
        }
    }

    var detail: String {
        switch self {
        case .normal: "Stop the alarm with a button."
        case .nfc: "Scan an NFC tag to stop the alarm."
        case .qrCode: "Scan a QR code to stop the alarm."
        }
    }

    var symbol: String {
        switch self {
        case .normal: "stop.circle"
        case .nfc: "wave.3.right"
        case .qrCode: "qrcode"
        }
    }

    var scanKind: AlarmStopTarget.Kind? {
        switch self {
        case .normal: nil
        case .nfc: .nfc
        case .qrCode: .qrCode
        }
    }
}
