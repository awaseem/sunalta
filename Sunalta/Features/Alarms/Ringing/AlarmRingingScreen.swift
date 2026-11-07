import SwiftUI

struct AlarmRingingScreen: View {
    @Environment(\.appTheme) private var theme
    @Environment(AlarmRuntime.self) private var runtime
    let alarm: AlarmRecord
    @State private var nfcScanner = NFCScannerUtil()
    @State private var showsQRScanner = false
    @State private var isWorking = false
    @State private var scanError: String?

    private var isSnoozed: Bool { alarm.snoozedUntil != nil }

    private var scanRequirement: String {
        switch alarm.exitPoint {
        case .normal: ""
        case .nfc: alarm.stopTargets.isEmpty ? "Any tag" : "Specific tag"
        case .qrCode: alarm.stopTargets.isEmpty ? "Any QR code" : "Specific QR code"
        }
    }

    var body: some View {
        NavigationStack {
            AlarmRingingArtwork(alarm: alarm, isRinging: !isSnoozed && !showsQRScanner,
                                isWorking: isWorking, scanError: scanError)
            .safeAreaInset(edge: .bottom) {
                GlassEffectContainer {
                    HStack(alignment: .bottom) {
                        if let snoozedUntil = alarm.snoozedUntil {
                            AlarmSnoozeStatus(until: snoozedUntil)
                        } else if alarm.snoozeEnabled {
                            Button("Snooze", action: snooze)
                                .buttonStyle(.appCapsule(fillsWidth: true))
                                .disabled(isWorking)
                                .accessibilityLabel("Snooze for \(alarm.snoozeDurationMinutes) minutes")
                        }
                        VStack {
                            if alarm.exitPoint != .normal {
                                Text(scanRequirement)
                                    .font(.caption)
                                    .foregroundStyle(theme.palette.secondaryForeground)
                                    .multilineTextAlignment(.center)
                            }
                            AlarmStopButton(exitPoint: alarm.exitPoint, isWorking: isWorking, onStop: startAction)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.palette.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close alarm", systemImage: "xmark", action: runtime.hideActiveAlarm)
                        .labelStyle(.iconOnly)
                        .foregroundStyle(theme.palette.control)
                        .disabled(isWorking)
                        .accessibilityHint("Keeps this alarm active. Reopen it from the alarms toolbar.")
                        .accessibilityIdentifier("hide-active-alarm")
                }
            }
        }
        .sheet(isPresented: $showsQRScanner) {
            AlarmQRDismissalScanner(alarm: alarm)
        }
        .task(id: runtime.scanRequestID) {
            if runtime.scanRequestID != nil { startAction() }
        }
        .onDisappear { nfcScanner.cancel() }
    }

    private func snooze() {
        guard !isWorking, !isSnoozed else { return }
        isWorking = true
        scanError = nil
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
#Preview("Snooze disabled") { AlarmRingingPreview(exitPoint: .normal, snoozeEnabled: false) }
#Preview("Snoozed alarm") { AlarmRingingPreview(exitPoint: .normal, snoozed: true) }
