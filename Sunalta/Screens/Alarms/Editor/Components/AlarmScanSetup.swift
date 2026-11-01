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
        VStack(alignment: .leading, spacing: 4) {
            Text(isConfigured
                 ? "Only this \(scanType) can stop your alarm."
                 : "Any \(scanType) can stop your alarm.")
                .font(.subheadline).foregroundStyle(theme.palette.secondaryForeground)
            Button(action: onScan) {
                Text(isConfigured
                     ? "Change specific \(isNFC ? "tag" : "code") to stop alarm"
                     : "Set specific \(isNFC ? "tag" : "code") to stop alarm")
                    .underline()
                    .font(.subheadline)
                    .frame(minHeight: 44, alignment: .topLeading)
                    .contentShape(.rect)
            }
            .accessibilityLabel(isConfigured ? "Replace \(scanType)" : "Set a specific \(scanType) to stop alarm")
            if isConfigured {
                Button(action: onClear) {
                    Text("Use any \(scanType)")
                        .underline()
                        .font(.subheadline)
                        .frame(minHeight: 44, alignment: .topLeading)
                        .contentShape(.rect)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .buttonStyle(.plain)
        .tint(theme.palette.control)
        .foregroundStyle(theme.palette.control)
    }
}
