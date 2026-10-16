import SwiftUI

struct AlarmStopButton: View {
    let exitPoint: AlarmExitPoint
    let isWorking: Bool
    let onStop: () -> Void

    var body: some View {
        Button("Stop", systemImage: exitPoint == .normal ? "stop.fill" : exitPoint.symbol, action: onStop)
            .buttonStyle(.appCapsule(fillsWidth: true))
            .disabled(isWorking)
            .accessibilityHint(exitPoint == .normal ? "Ends this alarm" : "Opens the scanner for this alarm")
    }
}
