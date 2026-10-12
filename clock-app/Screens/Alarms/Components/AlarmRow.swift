import SwiftUI

struct AlarmRow: View {
    @Environment(\.appTheme) private var theme
    let alarm: AlarmRecord
    var isUpdating = false
    var onEnabledChange: @MainActor @Sendable (Bool) -> Void = { _ in }

    private var repeatDescription: String {
        AlarmRepeatSummary.text(for: alarm.repeatDays)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    AlarmTimeLabel(hour: alarm.hour, minute: alarm.minute)
                    Spacer(minLength: 16)
                    AlarmEnabledToggle(alarm: alarm, isUpdating: isUpdating, onEnabledChange: onEnabledChange)
                }
                VStack(alignment: .leading, spacing: 8) {
                    AlarmTimeLabel(hour: alarm.hour, minute: alarm.minute)
                    AlarmEnabledToggle(alarm: alarm, isUpdating: isUpdating, onEnabledChange: onEnabledChange)
                }
            }
            if !alarm.label.isEmpty && alarm.label != "Alarm" {
                Text(alarm.label)
                    .font(.headline)
            }
            Text(repeatDescription)
                .font(.subheadline)
                .foregroundStyle(theme.palette.secondaryForeground)
            Label(alarm.exitPointSummary, systemImage: alarm.exitPoint.symbol)
                .font(.caption)
                .foregroundStyle(theme.palette.secondaryForeground)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.palette.surface, in: .rect(cornerRadius: 24))
        .accessibilityElement(children: .contain)
    }

}
