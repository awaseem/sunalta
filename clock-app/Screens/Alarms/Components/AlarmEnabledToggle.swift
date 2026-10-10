import SwiftUI

struct AlarmEnabledToggle: View {
    @Environment(\.appTheme) private var theme
    let alarm: AlarmRecord
    let isUpdating: Bool
    let onEnabledChange: @MainActor @Sendable (Bool) -> Void

    var body: some View {
        HStack {
            if isUpdating {
                ProgressView().accessibilityLabel("Updating alarm")
            }
            Toggle("Alarm enabled", isOn: Binding(
                get: { alarm.isEnabled }, set: onEnabledChange
            ))
            .labelsHidden()
            .tint(theme.palette.control)
            .accessibilityLabel("Alarm at \(AlarmTimeText.text(hour: alarm.hour, minute: alarm.minute))")
            .accessibilityValue(alarm.isEnabled ? "On" : "Off")
        }
    }
}
