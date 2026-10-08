import SwiftUI

struct AlarmExitPointOptions: View {
    @Binding var draft: AlarmExitPointDraft
    @State private var nfcScanner = NFCScannerUtil()
    @State private var scanError: String?
    @State private var scannerSheet: ScannerSheet?

    private enum ScannerSheet: String, Identifiable {
        case qrCode
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(spacing: 12) {
                ForEach(AlarmExitPoint.allCases) { option in
                    optionCard(option)
                }
            }
            .accessibilityLabel("Exit point")

            if draft.selection != .normal {
                scanSetup
            }
        }
        .sheet(item: $scannerSheet) { _ in
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

    private func optionCard(_ option: AlarmExitPoint) -> some View {
        let selected = draft.selection == option
        return Button {
            if !selected {
                cancelNFC()
                draft.select(option)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: option.symbol).font(.title3).frame(width: 28)
                VStack(alignment: .leading, spacing: 6) {
                    Text(option.title).font(.body.weight(.semibold))
                    Text(option.detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected ? Color.primary : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("exit-point-\(option.rawValue)")
    }

    private var scanSetup: some View {
        let isNFC = draft.selection == .nfc
        let type = isNFC ? "NFC tag" : "QR code"
        let configured = draft.scannedCode != nil
        return VStack(alignment: .leading, spacing: 12) {
            Label(configured ? "Specific \(type) set" : "Any \(type)",
                  systemImage: configured ? "checkmark.circle.fill" : draft.selection.symbol)
                .font(.headline)
            Text(configured
                 ? "Only this \(isNFC ? "tag" : "code") will be accepted."
                 : "Setup is optional. Leave it empty to accept any \(type).")
                .font(.subheadline).foregroundStyle(.secondary)
            Button {
                if isNFC { scanNFC() }
                else { scannerSheet = .qrCode }
            } label: {
                Label(configured ? "Replace \(type)" : "Scan a specific \(type)", systemImage: draft.selection.symbol)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .tint(.primary)
            if configured {
                Button("Use any \(type)") { draft.scannedCode = nil }
                    .buttonStyle(.plain)
                    .font(.subheadline)
                    .frame(minHeight: 44)
            }
        }
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
