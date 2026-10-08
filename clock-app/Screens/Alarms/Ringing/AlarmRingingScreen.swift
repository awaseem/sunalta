import SwiftUI

struct AlarmRingingScreen: View {
    @Environment(AlarmRuntime.self) private var runtime
    let alarm: AlarmRecord
    @State private var nfcScanner = NFCScannerUtil()
    @State private var showsQRScanner = false
    @State private var isWorking = false
    @State private var scanError: String?

    private var actionTitle: String {
        switch alarm.exitPoint {
        case .normal: "Stop"
        case .nfc: "Scan NFC to stop"
        case .qrCode: "Scan QR to stop"
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 16)
            VStack(spacing: 12) {
                Text("ALARM")
                    .font(.caption.weight(.semibold))
                    .tracking(3)
                    .foregroundStyle(.secondary)
                Text(String(format: "%02d:%02d", alarm.hour, alarm.minute))
                    .font(.system(size: 84, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(alarm.label.isEmpty ? "Time to get up" : alarm.label)
                    .font(.title2.weight(.medium))
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 16)
            Button(action: startAction) {
                VStack(spacing: 20) {
                    Image(systemName: alarm.exitPoint == .normal ? "stop.fill" : alarm.exitPoint.symbol)
                        .font(.system(size: 64, weight: .medium))
                        .accessibilityHidden(true)
                    Text(actionTitle)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .background(.orange, in: .rect(cornerRadius: 48))
                .foregroundStyle(.black)
            }
            .buttonStyle(.plain)
            .disabled(isWorking)
            .accessibilityHint(alarm.exitPoint == .normal ? "Ends this alarm" : "Opens the scanner for this alarm")

            if alarm.snoozeEnabled {
                Button("Snooze for \(alarm.snoozeDurationMinutes) min") {
                    guard !isWorking else { return }
                    isWorking = true
                    Task {
                        defer { isWorking = false }
                        do { try await runtime.snooze(alarm) }
                        catch { scanError = error.localizedDescription }
                    }
                }
                .font(.headline)
                .buttonStyle(.bordered)
                .disabled(isWorking)
            }

            VStack(spacing: 12) {
                if alarm.exitPoint != .normal {
                    Text(alarm.exitPointSummary)
                        .font(.headline)
                    Text("A scan ends this alarm. Stopping the ring gives you 30 seconds before it rings again.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if isWorking { ProgressView() }
                if let scanError {
                    Text(scanError)
                        .font(.subheadline)
                        .foregroundStyle(.red)
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
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showsQRScanner) {
            AlarmQRDismissalScanner(alarm: alarm)
        }
        .task(id: runtime.scanRequestID) {
            if runtime.scanRequestID != nil { startAction() }
        }
        .onDisappear { nfcScanner.cancel() }
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

#Preview("QR alarm") {
    AlarmRingingScreen(alarm: try! AlarmRecord(hour: 7, minute: 0, label: "Morning", exitPoint: .qrCode))
        .environment(AlarmRuntime.shared)
}

#Preview("Normal alarm") {
    AlarmRingingScreen(alarm: try! AlarmRecord(hour: 7, minute: 0))
        .environment(AlarmRuntime.shared)
}
