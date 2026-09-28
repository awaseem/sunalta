import SwiftUI

struct AlarmRow: View {
    let alarm: AlarmRecord

    private var repeatDescription: String {
        AlarmRepeatSummary.text(for: alarm.repeatDays)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    timeLabel
                    Spacer(minLength: 16)
                    statusLabel
                }
                VStack(alignment: .leading, spacing: 8) {
                    timeLabel
                    statusLabel
                }
            }
            Text(alarm.label.isEmpty ? "Alarm" : alarm.label)
                .font(.headline)
            Text(repeatDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if alarm.requiresScanToStop {
                Label("Scan to stop", systemImage: "qrcode.viewfinder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }

    private var timeLabel: some View {
        Text(String(format: "%02d:%02d", alarm.hour, alarm.minute))
            .font(.system(.largeTitle, design: .rounded, weight: .regular))
            .monospacedDigit()
    }

    private var statusLabel: some View {
        Text(alarm.isEnabled ? "On" : "Off")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(alarm.isEnabled ? .primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.quaternary, in: .capsule)
    }
}
