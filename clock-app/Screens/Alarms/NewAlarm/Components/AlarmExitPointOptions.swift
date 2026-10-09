import SwiftUI

struct AlarmExitPointOptions: View {
    @Binding var draft: AlarmExitPointDraft
    @State private var nfcScanner = NFCScannerUtil()
    @State private var scanError: String?
    @State private var showsQRSetup = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(spacing: 12) {
                ForEach(AlarmExitPoint.allCases) { option in
                    AlarmExitPointOptionButton(option: option, isSelected: draft.selection == option) {
                        select(option)
                    }
                }
            }

            if draft.selection != .normal {
                AlarmScanSetup(selection: draft.selection, isConfigured: draft.scannedCode != nil,
                               onScan: startScan, onClear: { draft.scannedCode = nil })
            }
        }
        .sheet(isPresented: $showsQRSetup) {
            AlarmQRSetupView(draft: $draft)
        }
        .alert("Couldn't scan NFC tag", isPresented: Binding(
            get: { scanError != nil }, set: { if !$0 { scanError = nil } }
        )) {
            Button("OK", role: .cancel) { scanError = nil }
        } message: {
            Text(scanError ?? "Please try again.")
        }
        .onDisappear { cancelNFC() }
    }

    private func select(_ option: AlarmExitPoint) {
        guard draft.selection != option else { return }
        cancelNFC()
        draft.select(option)
    }

    private func startScan() {
        if draft.selection == .nfc { scanNFC() }
        else { showsQRSetup = true }
    }

    private func scanNFC() {
        nfcScanner.onTagScanned = { result in
            guard draft.selection == .nfc else { return }
            draft.scannedCode = .init(kind: .nfc, value: result.id)
        }
        nfcScanner.onError = { scanError = $0 }
        nfcScanner.scan(alarmName: "your alarm")
    }

    private func cancelNFC() {
        nfcScanner.onTagScanned = nil
        nfcScanner.onError = nil
        nfcScanner.cancel()
    }
}

#Preview("Normal default") {
    @Previewable @State var draft = AlarmExitPointDraft()
    ScrollView { AlarmExitPointOptions(draft: $draft).padding(24) }
}

#Preview("Any NFC tag") {
    @Previewable @State var draft = AlarmExitPointDraft(selection: .nfc)
    ScrollView { AlarmExitPointOptions(draft: $draft).padding(24) }
}

#Preview("Specific QR code") {
    @Previewable @State var draft = AlarmExitPointDraft(
        selection: .qrCode, scannedCode: .init(kind: .qrCode, value: "my-alarm-qr")
    )
    ScrollView { AlarmExitPointOptions(draft: $draft).padding(24) }
}
