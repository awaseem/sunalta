import SwiftUI

struct AlarmRingingScreen: View {
    @Environment(\.appTheme) private var theme
    @Environment(AlarmRuntime.self) private var runtime
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let alarm: AlarmRecord
    @State private var nfcScanner = NFCScannerUtil()
    @State private var showsQRScanner = false
    @State private var isWorking = false
    @State private var scanError: String?
    @State private var bellCenter = CGPoint.zero
    @State private var rippleStarts: [Date] = []

    private var scanRequirement: String {
        switch alarm.exitPoint {
        case .normal: ""
        case .nfc: alarm.stopTargets.isEmpty ? "Any tag" : "Specific tag"
        case .qrCode: alarm.stopTargets.isEmpty ? "Any QR code" : "Specific QR code"
        }
    }

    var body: some View {
        ScrollView {
            VStack {
                AlarmBellView(isRinging: !showsQRScanner) {
                    rippleStarts = Array(rippleStarts.suffix(2)) + [.now]
                }
                    .frame(minHeight: 220, idealHeight: 320, maxHeight: 360)
                    .layoutPriority(-1)
                    .onGeometryChange(for: CGPoint.self) { geometry in
                        let frame = geometry.frame(in: .named("alarmRingingScreen"))
                        return CGPoint(x: frame.midX, y: frame.midY)
                    } action: { bellCenter = $0 }
                VStack(spacing: 12) {
                    if isWorking { ProgressView() }
                    if let scanError {
                        Text(scanError)
                            .font(.subheadline)
                            .foregroundStyle(theme.palette.error)
                            .accessibilityAddTraits(.updatesFrequently)
                    }
                }
                .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .top) {
            AlarmRingingHeader(alarm: alarm)
                .padding()
        }
        .safeAreaInset(edge: .bottom) {
            GlassEffectContainer {
                HStack(alignment: .bottom) {
                    if alarm.snoozeEnabled {
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
            }
            .padding()
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            AlarmRingingRipples(origin: bellCenter, pulses: rippleStarts,
                                isActive: !showsQRScanner && !reduceMotion && scenePhase == .active)
                .ignoresSafeArea()
        }
        .background(theme.palette.background.ignoresSafeArea())
        .coordinateSpace(name: "alarmRingingScreen")
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
#Preview("Snooze disabled") { AlarmRingingPreview(exitPoint: .normal, snoozeEnabled: false) }
