import SwiftUI

struct AlarmRow: View {
    let alarm: AlarmRecord
    var isUpdating = false
    var onEnabledChange: @MainActor @Sendable (Bool) -> Void = { _ in }

    private var repeatDescription: String {
        AlarmRepeatSummary.text(for: alarm.repeatDays)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    AlarmTimeLabel(hour: alarm.hour, minute: alarm.minute)
                    Spacer(minLength: 16)
                    AlarmEnabledToggle(alarm: alarm, isUpdating: isUpdating, onEnabledChange: onEnabledChange)
                }
                VStack(alignment: .leading, spacing: 8) {
                    AlarmTimeLabel(hour: alarm.hour, minute: alarm.minute)
                    AlarmEnabledToggle(alarm: alarm, isUpdating: isUpdating, onEnabledChange: onEnabledChange)
                }
            }
            Text(alarm.label.isEmpty ? "Alarm" : alarm.label)
                .font(.headline)
            Text(repeatDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Label(alarm.exitPointSummary, systemImage: alarm.exitPoint.symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 24))
        .accessibilityElement(children: .contain)
    }

}
