import AVFoundation
import CodeScanner
import SwiftUI

struct AlarmQRSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var draft: AlarmExitPointDraft
    @State private var scanError: String?
    @State private var permissionDenied = false
    @State private var scannerID = UUID()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Scan the specific QR code you'll use to stop your alarm.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .padding(.horizontal)
                AlarmQRCamera(scannerID: scannerID, isPaused: scanError != nil,
                              simulatorDescription: "Scan a specific QR code on a device, or leave setup empty to use any QR code.",
                              onScan: handleScan)
                    .padding(.horizontal)
                    .padding(.bottom)
                    .onAppear(perform: checkCameraRestriction)
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
                    AppSettingsButton(onOpen: { dismiss() })
                } else {
                    Button("Try again") { scannerID = UUID() }
                }
                Button("Cancel", role: .cancel) { dismiss() }
            } message: {
                Text(scanError ?? "Please try again.")
            }
        }
    }

    private func handleScan(_ result: Result<ScanResult, ScanError>) {
        switch result {
        case .success(let scan):
            guard draft.selection == .qrCode else { dismiss(); return }
            guard scan.type == .qr,
                  AlarmStopTarget.isValidScan(codeValue: scan.string, kind: .qrCode) else {
                scanError = "This QR code is empty. Try a different code."
                return
            }
            draft.scannedCode = .init(kind: .qrCode, value: scan.string)
            dismiss()
        case .failure:
            permissionDenied = [.denied, .restricted].contains(AVCaptureDevice.authorizationStatus(for: .video))
            scanError = permissionDenied
                ? "Allow camera access in Settings to scan your exit point's QR code."
                : "The camera couldn't scan this QR code. Please try again."
        }
    }

    private func checkCameraRestriction() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .restricted {
            permissionDenied = true
            scanError = "Camera access is restricted on this device. Leave setup empty to use any QR code."
        }
    }
}
