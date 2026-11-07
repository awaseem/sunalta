import AVFoundation
import CodeScanner
import SwiftUI

struct AlarmQRDismissalScanner: View {
    @Environment(\.appTheme) private var theme
    @Environment(AlarmRuntime.self) private var runtime
    @Environment(\.dismiss) private var dismiss
    let alarm: AlarmRecord
    @State private var scanError: String?
    @State private var scannerID = UUID()
    @State private var isFinishing = false

    private var cameraDenied: Bool {
        [.denied, .restricted].contains(AVCaptureDevice.authorizationStatus(for: .video))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(alarm.stopTargets.isEmpty ? "Scan any QR code to end this alarm." : "Scan the QR code you chose for this alarm.")
                    .font(.subheadline)
                    .foregroundStyle(theme.palette.secondaryForeground)
                    .multilineTextAlignment(.center)
                AlarmQRCamera(scannerID: scannerID, isPaused: isFinishing || scanError != nil,
                              simulatorDescription: "Scan your alarm's QR code using your iPhone's camera.",
                              onScan: handleScan)
                if let message = scanError {
                    Text(message).font(.subheadline).foregroundStyle(theme.palette.error)
                    if cameraDenied {
                        AppSettingsButton(title: "Open Camera Settings")
                            .buttonStyle(.appCapsule(fillsWidth: true))
                    } else {
                        Button("Scan again") {
                            scanError = nil
                            scannerID = UUID()
                        }
                        .buttonStyle(.appCapsule(fillsWidth: true))
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.palette.background)
            .navigationTitle("Scan to stop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { dismiss() }
                }
            }
        }
    }

    private func handleScan(_ result: Result<ScanResult, ScanError>) {
        switch result {
        case .success(let scan):
            guard !isFinishing, scan.type == .qr else { return }
            isFinishing = true
            Task { await finishScan(scan.string) }
        case .failure:
            scanError = cameraDenied
                ? "Allow camera access in Settings to scan your QR code."
                : "The camera couldn't read this code. Try again."
        }
    }

    private func finishScan(_ code: String) async {
        defer { isFinishing = false }
        do {
            try await runtime.finish(alarm, code: code, kind: .qrCode)
            dismiss()
        } catch { scanError = error.localizedDescription }
    }
}
