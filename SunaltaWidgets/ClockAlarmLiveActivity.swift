import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

struct ClockAlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<ClockAlarmMetadata>.self) { context in
            AlarmCountdownContent(metadata: context.attributes.metadata, state: context.state)
                .padding(20)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.orange)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.metadata?.title ?? "Alarm", systemImage: symbol(context))
                        .font(.headline)
                        .lineLimit(2)
                        .truncationMode(.tail)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    AlarmCountdownTime(mode: context.state.mode)
                        .font(.title2.weight(.semibold))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.attributes.metadata?.statusText ?? "Snoozed")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        AlarmCountdownAction(metadata: context.attributes.metadata, systemID: context.state.alarmID)
                    }
                }
            } compactLeading: {
                Image(systemName: symbol(context)).foregroundStyle(.orange)
            } compactTrailing: {
                AlarmCountdownTime(mode: context.state.mode)
                    .monospacedDigit()
                    .frame(maxWidth: 60)
            } minimal: {
                Image(systemName: symbol(context)).foregroundStyle(.orange)
            }
            .keylineTint(.orange)
        }
    }

    private func symbol(_ context: ActivityViewContext<AlarmAttributes<ClockAlarmMetadata>>) -> String {
        context.attributes.metadata?.scanSymbol ?? "alarm"
    }
}




#Preview("NFC scan reminder") {
    AlarmCountdownContent(
        metadata: .init(alarmID: UUID(), token: "preview", title: "Morning", scanSymbol: "wave.3.right", countdownKind: .scanReminder),
        state: .init(alarmID: UUID(), mode: .countdown(.init(
            totalCountdownDuration: 30, previouslyElapsedDuration: 0,
            startDate: .now, fireDate: .now.addingTimeInterval(30)
        )))
    )
    .padding(20)
    .background(.black)
}

#Preview("Snoozed alarm") {
    AlarmCountdownContent(
        metadata: .init(alarmID: UUID(), token: "preview", title: "Morning", scanSymbol: nil, countdownKind: .snooze),
        state: .init(alarmID: UUID(), mode: .countdown(.init(
            totalCountdownDuration: 600, previouslyElapsedDuration: 0,
            startDate: .now, fireDate: .now.addingTimeInterval(600)
        )))
    )
    .padding(20)
    .background(.black)
}
