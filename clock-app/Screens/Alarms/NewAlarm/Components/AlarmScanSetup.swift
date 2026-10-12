import SwiftUI

struct AlarmScanSetup: View {
    @Environment(\.appTheme) private var theme
    let selection: AlarmExitPoint
    let isConfigured: Bool
    let onScan: () -> Void
    let onClear: () -> Void

    private var isNFC: Bool { selection == .nfc }
    private var scanType: String { isNFC ? "NFC tag" : "QR code" }

    var body: some View {
        VStack(alignment: .leading) {
            Label(isConfigured ? "Specific \(scanType) set" : "Any \(scanType)",
                  systemImage: isConfigured ? "checkmark.circle.fill" : selection.symbol)
                .font(.headline)
            Text(isConfigured
                 ? "Only this \(isNFC ? "tag" : "code") will be accepted."
                 : "Setup is optional. Leave it empty to accept any \(scanType).")
                .font(.subheadline).foregroundStyle(theme.palette.secondaryForeground)
            GlassEffectContainer {
                VStack {
                    Button(isConfigured ? "Replace \(scanType)" : "Scan a specific \(scanType)",
                           systemImage: selection.symbol, action: onScan)
                        .buttonStyle(.appCapsule(fillsWidth: true))
                    if isConfigured {
                        Button("Use any \(scanType)", action: onClear)
                            .buttonStyle(.appCapsule(fillsWidth: true))
                    }
                }
            }
        }
    }
}
