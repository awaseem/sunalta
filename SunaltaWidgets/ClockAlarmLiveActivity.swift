import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

struct ClockAlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<ClockAlarmMetadata>.self) { context in
            let palette = currentPalette
            AlarmCountdownContent(metadata: context.attributes.metadata, state: context.state, palette: palette)
                .padding()
                .activityBackgroundTint(palette.background)
                .activitySystemActionForegroundColor(palette.foreground)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.metadata?.title ?? "Alarm")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .truncationMode(.tail)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    AlarmCountdownTime(mode: context.state.mode)
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading) {
                        Text(context.attributes.metadata?.statusText ?? "Snoozed")
                            .font(.subheadline)
                            .foregroundStyle(ThemePalette.midnight.secondaryForeground)
                        AlarmCountdownAction(metadata: context.attributes.metadata, systemID: context.state.alarmID,
                                             palette: .midnight)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            } compactLeading: {
                Image(systemName: symbol(context)).foregroundStyle(.white)
            } compactTrailing: {
                AlarmCountdownTime(mode: context.state.mode)
                    .monospacedDigit()
                    .frame(maxWidth: 60)
                    .foregroundStyle(.white)
            } minimal: {
                Image(systemName: symbol(context)).foregroundStyle(.white)
            }
            .keylineTint(.white)
        }
    }

    private var currentPalette: ThemePalette {
        guard let defaults = UserDefaults(suiteName: ClockWidgetPreferences.appGroup) else { return .white }
        return .resolve(id: ClockWidgetPreferencesStore(defaults: defaults).load().themeID)
    }

    private func symbol(_ context: ActivityViewContext<AlarmAttributes<ClockAlarmMetadata>>) -> String {
        context.attributes.metadata?.scanSymbol ?? "alarm"
    }
}
