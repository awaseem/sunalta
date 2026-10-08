import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

@main
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
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    AlarmCountdownTime(mode: context.state.mode)
                        .font(.title2.weight(.semibold))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(status(context.attributes.metadata))
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

private func status(_ metadata: ClockAlarmMetadata?) -> String {
    metadata?.countdownKind == .scanReminder ? "Scan to end the alarm" : "Snoozed"
}

private struct AlarmCountdownContent: View {
    let metadata: ClockAlarmMetadata?
    let state: AlarmPresentationState

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Label(metadata?.title ?? "Alarm", systemImage: metadata?.scanSymbol ?? "alarm")
                    .font(.headline)
                    .lineLimit(1)
                Text(status(metadata)).font(.subheadline).foregroundStyle(.secondary)
                AlarmCountdownTime(mode: state.mode)
                    .font(.system(.largeTitle, design: .rounded, weight: .semibold))
            }
            Spacer(minLength: 0)
            AlarmCountdownAction(metadata: metadata, systemID: state.alarmID)
        }
        .foregroundStyle(.white)
    }
}

private struct AlarmCountdownTime: View {
    let mode: AlarmPresentationState.Mode

    var body: some View {
        switch mode {
        case .countdown(let countdown):
            Text(timerInterval: countdown.startDate...countdown.fireDate, countsDown: true)
                .monospacedDigit()
                .accessibilityLabel("Time until the alarm rings")
        case .paused(let paused):
            let remaining = Int(max(0, paused.totalCountdownDuration - paused.previouslyElapsedDuration))
            Text(String(format: "%d:%02d", remaining / 60, remaining % 60)).monospacedDigit()
        case .alert:
            Text("Ringing")
        @unknown default:
            Text("Alarm")
        }
    }
}

private struct AlarmCountdownAction: View {
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
