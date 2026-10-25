import SwiftUI

struct AlarmRepeatPicker: View {
    @Environment(\.appTheme) private var theme
    @Binding var repeatDays: Set<ClockWeekday>
    @ScaledMetric(relativeTo: .body) private var dayDiameter = 44

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(AlarmRepeatSummary.orderedDays, id: \.rawValue) { day in
                    Button {
                        if repeatDays.contains(day) { repeatDays.remove(day) }
                        else { repeatDays.insert(day) }
                    } label: {
                        Text(String(day.abbreviation.prefix(1)))
                            .font(.body.bold())
                            .frame(width: dayDiameter, height: dayDiameter)
                            .foregroundStyle(repeatDays.contains(day)
                                ? theme.palette.onControl
                                : theme.palette.foreground)
                            .background(repeatDays.contains(day)
                                ? theme.palette.control
                                : theme.palette.surface, in: .circle)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(day.name)
                    .accessibilityValue(repeatDays.contains(day) ? "Selected" : "Not selected")
                    .accessibilityAddTraits(repeatDays.contains(day) ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .defaultScrollAnchor(.center, for: .alignment)
        .frame(height: dayDiameter)
        .frame(maxWidth: 420)
        .padding(.top, 12)
    }
}
