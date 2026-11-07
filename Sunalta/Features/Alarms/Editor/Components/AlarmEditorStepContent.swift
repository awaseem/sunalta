import SwiftUI

struct AlarmEditorStepContent: View {
    @Environment(\.appTheme) private var theme
    let step: AlarmEditorStep
    @Binding var draft: AlarmEditorDraft

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(step.title).font(.title2.bold()).accessibilityAddTraits(.isHeader)
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
                VStack(alignment: .leading) {
                    AlarmNameField(name: $draft.name)
                    AlarmSoundPicker(selection: $draft.soundSelection)
                }
                .padding(.horizontal)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
    }
}
