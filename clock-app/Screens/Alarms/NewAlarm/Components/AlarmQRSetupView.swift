import AVFoundation
import CodeScanner
import SwiftUI

struct AlarmQRSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Binding var scannedCode: AlarmExitPointDraft.ScannedCode?
    @Binding var savedTarget: AlarmStopTarget?
    @State private var scanError: String?
    @State private var permissionDenied = false
    @State private var scannerID = UUID()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Scan the QR code at your exit point.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .padding(.horizontal)
                scanner
            }
            .navigationTitle("Set up QR code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Couldn't scan QR code", isPresented: Binding(
                get: { scanError != nil }, set: { if !$0 { scanError = nil } }
            )) {
                if permissionDenied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        dismiss()
                    }
                } else {
                    Button("Try again") { scannerID = UUID() }
                }
                Button("Cancel", role: .cancel) { dismiss() }
            } message: {
                Text(scanError ?? "Please try again.")
            }
        }
    }

    @ViewBuilder
    private var scanner: some View {
        #if targetEnvironment(simulator)
        ContentUnavailableView(
            "Camera scanning needs an iPhone", systemImage: "qrcode.viewfinder",
            description: Text("Set up your QR code on a device, or use any QR code or NFC tag for now.")
        )
        #else
        cameraScanner
        #endif
    }

    private var cameraScanner: some View {
        CodeScannerView(codeTypes: [.qr], scanMode: .once, showViewfinder: true,
                        requiresPhotoOutput: false, isPaused: scanError != nil) { result in
            switch result {
            case .success(let scan):
                guard scan.type == .qr,
                      AlarmStopTarget.isValidScan(codeValue: scan.string, kind: .qrCode) else {
                    scanError = "This QR code is empty. Try a different code."
                    return
                }
                scannedCode = .init(kind: .qrCode, value: scan.string)
                savedTarget = nil
                dismiss()
            case .failure:
                permissionDenied = AVCaptureDevice.authorizationStatus(for: .video) == .denied
                    || AVCaptureDevice.authorizationStatus(for: .video) == .restricted
                scanError = permissionDenied
                    ? "Allow camera access in Settings to scan your exit point's QR code."
                    : "The camera couldn't scan this QR code. Please try again."
            }
        }
        .id(scannerID)
        .clipShape(.rect(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.bottom)
        .onAppear {
            if AVCaptureDevice.authorizationStatus(for: .video) == .restricted {
                permissionDenied = true
                scanError = "Camera access is restricted on this device. You can use an NFC tag or skip setup."
            }
        }
    }
}
