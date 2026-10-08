import AVFoundation
import CodeScanner
import SwiftUI

struct AlarmQRDismissalScanner: View {
    @Environment(AlarmRuntime.self) private var runtime
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
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
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                #if targetEnvironment(simulator)
                ContentUnavailableView("Use your iPhone's camera", systemImage: "qrcode.viewfinder")
                #else
                camera
                #endif
                if let message = scanError {
                    Text(message).font(.subheadline).foregroundStyle(.red)
                    if cameraDenied {
                        Button("Open Camera Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                    } else {
                        Button("Scan again") {
                            scanError = nil
                            scannerID = UUID()
                        }
                    }
                }
            }
            .padding(24)
            .navigationTitle("Scan to stop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { dismiss() }
                }
            }
        }
    }

    private var camera: some View {
        CodeScannerView(codeTypes: [.qr], scanMode: .once, showViewfinder: true,
                        requiresPhotoOutput: false, isPaused: isFinishing || scanError != nil) { result in
            switch result {
            case .success(let scan):
                guard !isFinishing, scan.type == .qr else { return }
                isFinishing = true
                Task {
                    defer { isFinishing = false }
                    do {
                        try await runtime.finish(alarm, code: scan.string, kind: .qrCode)
                        dismiss()
                    } catch { scanError = error.localizedDescription }
                }
            case .failure:
                scanError = cameraDenied
                    ? "Allow camera access in Settings to scan your QR code."
                    : "The camera couldn't read this code. Try again."
            }
        }
        .id(scannerID)
        .clipShape(.rect(cornerRadius: 24))
    }
}
