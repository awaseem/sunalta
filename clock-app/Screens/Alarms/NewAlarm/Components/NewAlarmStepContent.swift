import SwiftUI

struct NewAlarmStepContent: View {
    @Environment(\.appTheme) private var theme
    let step: NewAlarmStep
    @Binding var draft: NewAlarmDraft

    var body: some View {
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
            switch step {
            case .time:
                DatePicker("Alarm time", selection: $draft.time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "en_GB"))
                    .frame(maxWidth: .infinity)
            case .repeatDays:
                AlarmRepeatPicker(repeatDays: $draft.repeatDays)
            case .snooze:
                AlarmSnoozeOptions(snoozeEnabled: $draft.snoozeEnabled, snoozeMinutes: $draft.snoozeMinutes)
            case .exitPoint:
                AlarmExitPointOptions(draft: $draft.exitPoint)
            }
        }
        .padding()
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }
}
