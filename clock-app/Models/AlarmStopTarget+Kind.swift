import Foundation

nonisolated extension AlarmStopTarget {
    enum Kind: String, Sendable {
        case nfc, qrCode
    }
}
