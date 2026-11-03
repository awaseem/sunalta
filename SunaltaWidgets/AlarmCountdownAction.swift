import AlarmKit
import AppIntents
import SwiftUI

struct AlarmCountdownAction: View {
    let metadata: ClockAlarmMetadata?
    let systemID: UUID
    let palette: ThemePalette

    var body: some View {
        if let metadata {
            Group {
                if let symbol = metadata.scanSymbol {
                    Button(intent: ScanClockAlarmIntent(alarmID: metadata.alarmID, systemID: systemID, token: metadata.token)) {
                        Label(metadata.actionTitle, systemImage: symbol)
                    }
                } else {
                    Button(intent: StopClockAlarmIntent(alarmID: metadata.alarmID, systemID: systemID, token: metadata.token)) {
                        Label("Stop", systemImage: "stop.fill")
                    }
                }
            }
            .font(.headline)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(palette.control)
            .foregroundStyle(palette.onControl)
            .fixedSize(horizontal: true, vertical: false)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }
}
