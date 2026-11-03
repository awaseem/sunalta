import AlarmKit
import AppIntents
import SwiftUI

struct AlarmCountdownContent: View {
    let metadata: ClockAlarmMetadata?
    let state: AlarmPresentationState
    let palette: ThemePalette

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(metadata?.title ?? "Alarm")
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(metadata?.statusText ?? "Snoozed")
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryForeground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            HStack {
                AlarmCountdownTime(mode: state.mode)
                    .font(.largeTitle)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                AlarmCountdownAction(metadata: metadata, systemID: state.alarmID, palette: palette)
            }
        }
        .foregroundStyle(palette.foreground)
        // Keep the countdown and scan action visible within the Lock Screen's limited activity height.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}
