import SwiftUI

struct AlarmRepeatPicker: View {
    @Environment(\.colorScheme) private var colorScheme
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
                            ? (colorScheme == .dark ? Color.black : Color.white)
                            : Color.primary)
                        .background(repeatDays.contains(day)
                            ? (colorScheme == .dark ? Color.white : Color.black)
                            : Color.primary.opacity(0.08), in: .circle)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
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
