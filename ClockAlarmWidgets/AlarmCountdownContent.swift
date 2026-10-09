import AlarmKit
import AppIntents
import SwiftUI

struct AlarmCountdownContent: View {
    let metadata: ClockAlarmMetadata?
    let state: AlarmPresentationState

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Label(metadata?.title ?? "Alarm", systemImage: metadata?.scanSymbol ?? "alarm")
                    .font(.headline)
                    .lineLimit(1)
                Text(metadata?.statusText ?? "Snoozed").font(.subheadline).foregroundStyle(.secondary)
                AlarmCountdownTime(mode: state.mode)
                    .font(.system(.largeTitle, design: .rounded, weight: .semibold))
            }
            Spacer(minLength: 0)
            AlarmCountdownAction(metadata: metadata, systemID: state.alarmID)
        }
        .foregroundStyle(.white)
    }
}
