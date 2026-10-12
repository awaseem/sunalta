import SwiftUI

struct AlarmStopButton: View {
    let exitPoint: AlarmExitPoint
    let isWorking: Bool
    let onStop: () -> Void

    private var title: String {
        switch exitPoint {
        case .normal: "Stop"
        case .nfc: "Scan NFC to stop"
        case .qrCode: "Scan QR to stop"
        }
    }

    var body: some View {
        Button(title, systemImage: exitPoint == .normal ? "stop.fill" : exitPoint.symbol, action: onStop)
            .buttonStyle(.appCapsule(fillsWidth: true))
            .disabled(isWorking)
            .accessibilityHint(exitPoint == .normal ? "Ends this alarm" : "Opens the scanner for this alarm")
    }
}
