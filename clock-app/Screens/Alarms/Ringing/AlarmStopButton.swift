import SwiftUI

struct AlarmStopButton: View {
    let exitPoint: AlarmExitPoint
    let isWorking: Bool
    let onStop: () -> Void
    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize = 64

    private var title: String {
        switch exitPoint {
        case .normal: "Stop"
        case .nfc: "Scan NFC to stop"
        case .qrCode: "Scan QR to stop"
        }
    }

    var body: some View {
        Button(action: onStop) {
            VStack {
                Image(systemName: exitPoint == .normal ? "stop.fill" : exitPoint.symbol)
                    .font(.system(size: symbolSize, weight: .medium))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 240)
            .background(.orange, in: .rect(cornerRadius: 48))
            .foregroundStyle(.black)
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
        .accessibilityHint(exitPoint == .normal ? "Ends this alarm" : "Opens the scanner for this alarm")
    }
}
