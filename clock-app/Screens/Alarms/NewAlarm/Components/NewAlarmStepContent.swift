import SwiftUI

struct NewAlarmStepContent: View {
    @Environment(\.appTheme) private var theme
    let step: NewAlarmStep
    @Binding var draft: NewAlarmDraft

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline) {
                    Text(step.title).font(.title2.bold()).accessibilityAddTraits(.isHeader)
                    if step == .time {
                        Spacer()
                        Text("24 H").font(.caption.weight(.medium)).foregroundStyle(theme.palette.secondaryForeground)
                    }
                }
                if step != .time {
                    Text(step.subtitle).font(.subheadline).foregroundStyle(theme.palette.secondaryForeground)
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: 560, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            switch step {
            case .time:
                AlarmTimePicker(time: $draft.time)
                    .padding(.horizontal)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
            case .repeatDays:
                AlarmRepeatPicker(repeatDays: $draft.repeatDays)
                    .padding(.horizontal)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
            case .snooze:
                AlarmSnoozeOptions(snoozeEnabled: $draft.snoozeEnabled, snoozeMinutes: $draft.snoozeMinutes)
                    .padding(.horizontal)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
            case .exitPoint:
                AlarmExitPointOptions(draft: $draft.exitPoint)
            case .name:
                AlarmNameField(name: $draft.name)
                    .padding(.horizontal)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
    }
}
