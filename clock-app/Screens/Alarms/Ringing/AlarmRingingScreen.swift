import SwiftUI

struct AlarmRingingScreen: View {
    @Environment(\.appTheme) private var theme
    @Environment(AlarmRuntime.self) private var runtime
    let alarm: AlarmRecord
    @State private var nfcScanner = NFCScannerUtil()
    @State private var showsQRScanner = false
    @State private var isWorking = false
    @State private var scanError: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 16)
            AlarmRingingHeader(alarm: alarm)
            Spacer(minLength: 16)
            GlassEffectContainer {
                VStack {
                    AlarmStopButton(exitPoint: alarm.exitPoint, isWorking: isWorking, onStop: startAction)
                    if alarm.snoozeEnabled {
                        Button("Snooze for \(alarm.snoozeDurationMinutes) min", action: snooze)
                            .buttonStyle(.appCapsule(fillsWidth: true))
                            .disabled(isWorking)
                    }
                }
            }

            VStack(spacing: 12) {
                if alarm.exitPoint != .normal {
                    Text(alarm.exitPointSummary)
                        .font(.headline)
                    Text("A scan ends this alarm. Stopping the ring gives you 30 seconds before it rings again.")
                        .font(.subheadline)
                        .foregroundStyle(theme.palette.secondaryForeground)
                }
                if isWorking { ProgressView() }
                if let scanError {
                    Text(scanError)
                        .font(.subheadline)
                        .foregroundStyle(theme.palette.error)
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }
            .multilineTextAlignment(.center)
            .frame(minHeight: 84, alignment: .top)
            Spacer(minLength: 16)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.palette.background.ignoresSafeArea())
        .sheet(isPresented: $showsQRScanner) {
            AlarmQRDismissalScanner(alarm: alarm)
        }
        .task(id: runtime.scanRequestID) {
            if runtime.scanRequestID != nil { startAction() }
        }
        .onDisappear { nfcScanner.cancel() }
    }

    private func snooze() {
        guard !isWorking else { return }
        isWorking = true
        Task {
            defer { isWorking = false }
            do { try await runtime.snooze(alarm) }
            catch { scanError = error.localizedDescription }
        }
    }

    private func startAction() {
        guard !isWorking, !showsQRScanner else { return }
        isWorking = true
        scanError = nil
        Task {
            defer { isWorking = false }
            do {
                switch alarm.exitPoint {
                case .normal:
                    try await runtime.finish(alarm)
                case .qrCode:
                    try await runtime.prepareToScan(alarm)
                    showsQRScanner = true
                case .nfc:
                    try await runtime.prepareToScan(alarm)
                    nfcScanner.onError = { scanError = $0 }
                    nfcScanner.onTagScanned = { scan in
                        Task {
                            do { try await runtime.finish(alarm, code: scan.id, kind: .nfc) }
                            catch { scanError = error.localizedDescription }
                        }
                    }
                    nfcScanner.scan(alarmName: alarm.label.isEmpty ? "your alarm" : alarm.label)
                }
            } catch {
                scanError = error.localizedDescription
            }
        }
    }
}

#Preview("QR alarm") { AlarmRingingPreview(exitPoint: .qrCode) }
#Preview("Normal alarm") { AlarmRingingPreview(exitPoint: .normal) }
