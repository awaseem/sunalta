import SwiftData
import SwiftUI

struct AlarmExitPointOptions: View {
    @Query(sort: \AlarmStopTarget.name) private var savedTargets: [AlarmStopTarget]
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
            VStack(alignment: .leading, spacing: 8) {
                Text("Exit point name (optional)")
                    .font(.subheadline).foregroundStyle(.secondary)
                TextField("Bathroom, kitchen, hallway…", text: $draft.name)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .padding(16)
                    .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 16))
                    .accessibilityLabel("Exit point name, optional")
            }

            selectionRow(
                title: "Any QR code or NFC tag", detail: "No setup needed. Scan either one to stop your alarm.",
                icon: "qrcode.viewfinder", selected: draft.usesAnyScan
            ) {
                draft.scannedCode = nil
                draft.savedTarget = nil
            }

            if let code = draft.scannedCode {
                Label(code.kind == .nfc ? "NFC tag set up" : "QR code set up",
                      systemImage: "checkmark.circle.fill")
                    .font(.headline)
                Text("Only this \(code.kind == .nfc ? "tag" : "code") will stop your alarm.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button { scanNFC() } label: {
                    Label("Set up NFC", systemImage: "wave.3.right")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                Button { scannerSheet = .qrCode } label: {
                    Label("Set up QR", systemImage: "qrcode")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
            }
            .buttonStyle(.bordered)
            .tint(.primary)

            if !savedTargets.isEmpty {
                Text("Saved exit points").font(.headline)
                ForEach(savedTargets.filter { (try? $0.validate()) != nil }) { target in
                    selectionRow(
                        title: target.name, detail: target.kind == .nfc ? "NFC tag" : "QR code",
                        icon: target.kind == .nfc ? "wave.3.right" : "qrcode",
                        selected: draft.savedTarget?.id == target.id
                    ) {
                        draft = AlarmExitPointDraft(name: target.name, savedTarget: target)
                    }
                }
            }
        }
        .sheet(item: $scannerSheet) { _ in
            AlarmQRSetupView(scannedCode: $draft.scannedCode, savedTarget: $draft.savedTarget)
        }
        .alert("Couldn't scan NFC tag", isPresented: Binding(
            get: { scanError != nil }, set: { if !$0 { scanError = nil } }
        )) {
            Button("OK", role: .cancel) { scanError = nil }
        } message: {
            Text(scanError ?? "Please try again.")
        }
        .onDisappear {
            nfcScanner.onTagScanned = nil
            nfcScanner.onError = nil
            nfcScanner.cancel()
        }
    }

    private func selectionRow(
        title: String, detail: String, icon: String, selected: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.title3).frame(width: 28)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.body.weight(.medium))
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected ? Color.primary : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func scanNFC() {
        nfcScanner.onTagScanned = { result in
            draft.scannedCode = .init(kind: .nfc, value: result.id)
            draft.savedTarget = nil
        }
        nfcScanner.onError = { scanError = $0 }
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        nfcScanner.scan(alarmName: name.isEmpty ? "your exit point" : name)
    }
}

#Preview("Exit point") {
    @Previewable @State var draft = AlarmExitPointDraft()
    ScrollView { AlarmExitPointOptions(draft: $draft).padding(24) }
        .modelContainer(for: [AlarmRecord.self, AlarmStopTarget.self], inMemory: true)
}

#Preview("Configured exit point") {
    @Previewable @State var draft = AlarmExitPointDraft(
        name: "Bathroom", scannedCode: .init(kind: .qrCode, value: "bathroom")
    )
    ScrollView { AlarmExitPointOptions(draft: $draft).padding(24) }
        .modelContainer(for: [AlarmRecord.self, AlarmStopTarget.self], inMemory: true)
}
