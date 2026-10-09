import AlarmKit
import AppIntents
import SwiftUI

struct AlarmCountdownAction: View {
    let metadata: ClockAlarmMetadata?
    let systemID: UUID

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
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .foregroundStyle(.black)
        }
    }
}
