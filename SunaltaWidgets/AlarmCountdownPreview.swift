import AlarmKit
import SwiftUI

struct AlarmCountdownPreview: View {
    var palette: ThemePalette = .white
    var scanSymbol: String? = "wave.3.right"
    var title = "Morning"
    var kind: ClockAlarmMetadata.CountdownKind = .scanReminder

    var body: some View {
        AlarmCountdownContent(
            metadata: .init(alarmID: UUID(), token: "preview", title: title,
                            scanSymbol: scanSymbol, countdownKind: kind),
            state: .init(alarmID: UUID(), mode: .paused(.init(
                totalCountdownDuration: kind == .snooze ? 600 : 30, previouslyElapsedDuration: 0
            ))),
            palette: palette
        )
        .padding()
        .background(palette.background, in: .rect(cornerRadius: 24))
    }
}

#Preview("White · NFC") { AlarmCountdownPreview() }
#Preview("Midnight · QR") { AlarmCountdownPreview(palette: .midnight, scanSymbol: "qrcode") }
#Preview("Grass · NFC") { AlarmCountdownPreview(palette: .grass) }
#Preview("Snoozed QR alarm") { AlarmCountdownPreview(scanSymbol: "qrcode", kind: .snooze) }
#Preview("Snoozed alarm") { AlarmCountdownPreview(scanSymbol: nil, kind: .snooze) }
#Preview("Long name · Larger text") {
    AlarmCountdownPreview(scanSymbol: "qrcode", title: "An early start for a long morning")
        .environment(\.dynamicTypeSize, .xxxLarge)
}
#Preview("Accessibility text") {
    AlarmCountdownPreview(scanSymbol: "qrcode", title: "An early start for a long morning")
        .environment(\.dynamicTypeSize, .accessibility3)
}
