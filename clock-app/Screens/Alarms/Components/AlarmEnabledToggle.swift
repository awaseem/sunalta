import SwiftUI

struct AlarmEnabledToggle: View {
    @Environment(\.appTheme) private var theme
    let hour: Int
    let minute: Int
    let isEnabled: Bool
    let isUpdating: Bool
    let onEnabledChange: @MainActor @Sendable (Bool) -> Void

    var body: some View {
        HStack {
            if isUpdating {
                ProgressView().accessibilityLabel("Updating alarm")
            }
            Toggle("Alarm enabled", isOn: Binding(
                get: { isEnabled }, set: onEnabledChange
            ))
            .labelsHidden()
            .tint(theme.palette.selection)
            .accessibilityLabel("Alarm at \(AlarmTimeText.text(hour: hour, minute: minute))")
            .accessibilityValue(isEnabled ? "On" : "Off")
        }
    }
}
