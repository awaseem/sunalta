import SwiftUI

struct AlarmRepeatPicker: View {
    @Environment(\.appTheme) private var theme
    @Binding var repeatDays: Set<ClockWeekday>

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AlarmRepeatSummary.orderedDays, id: \.rawValue) { day in
                Button {
                    if repeatDays.contains(day) { repeatDays.remove(day) }
                    else { repeatDays.insert(day) }
                } label: {
                    Text(String(day.abbreviation.prefix(1)))
                        .font(.body.weight(.semibold))
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .foregroundStyle(repeatDays.contains(day)
                            ? theme.palette.onControl
                            : theme.palette.foreground)
                        .background(repeatDays.contains(day)
                            ? theme.palette.control
                            : theme.palette.surface, in: .circle)
                        .frame(minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day.name)
                .accessibilityValue(repeatDays.contains(day) ? "Selected" : "Not selected")
                .accessibilityAddTraits(repeatDays.contains(day) ? .isSelected : [])
            }
        }
        .frame(maxWidth: 420)
    }
}
