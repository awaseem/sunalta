import AVFoundation
import CodeScanner
import SwiftUI

/// CodeScanner is the existing camera integration; its callbacks stay at this boundary.
struct AlarmQRCamera: View {
    let scannerID: UUID
    let isPaused: Bool
    let simulatorDescription: String
    let onScan: (Result<ScanResult, ScanError>) -> Void

    var body: some View {
        #if targetEnvironment(simulator)
        ContentUnavailableView("Camera scanning needs an iPhone", systemImage: "qrcode.viewfinder",
                               description: Text(simulatorDescription))
        #else
        CodeScannerView(codeTypes: [.qr], scanMode: .once, showViewfinder: true,
                        requiresPhotoOutput: false, isPaused: isPaused, completion: onScan)
            .id(scannerID)
            .clipShape(.rect(cornerRadius: 20))
        #endif
    }
}
