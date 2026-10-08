import SwiftUI

struct AlarmRow: View {
    let alarm: AlarmRecord
    var isUpdating = false
    var onEnabledChange: (Bool) -> Void = { _ in }

    private var repeatDescription: String {
        AlarmRepeatSummary.text(for: alarm.repeatDays)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    timeLabel
                    Spacer(minLength: 16)
                    enabledToggle
                }
                VStack(alignment: .leading, spacing: 8) {
                    timeLabel
                    enabledToggle
                }
            }
            Text(alarm.label.isEmpty ? "Alarm" : alarm.label)
                .font(.headline)
            Text(repeatDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if alarm.requiresScanToStop {
                Label(alarm.exitPointSummary, systemImage: "qrcode.viewfinder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 24))
        .accessibilityElement(children: .contain)
    }

    private var timeLabel: some View {
        Text(String(format: "%02d:%02d", alarm.hour, alarm.minute))
            .font(.system(.largeTitle, design: .rounded, weight: .regular))
            .monospacedDigit()
    }

    private var enabledToggle: some View {
        HStack(spacing: 10) {
            if isUpdating {
                ProgressView()
                    .accessibilityLabel("Updating alarm")
            }
            Toggle("Alarm enabled", isOn: Binding(
                get: { alarm.isEnabled }, set: onEnabledChange
            ))
            .labelsHidden()
            .tint(.primary)
            .accessibilityLabel("Alarm at \(String(format: "%02d:%02d", alarm.hour, alarm.minute))")
            .accessibilityValue(alarm.isEnabled ? "On" : "Off")
        }
    }
}
