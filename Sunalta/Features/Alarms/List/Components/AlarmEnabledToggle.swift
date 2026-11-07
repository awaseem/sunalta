import SwiftUI

struct AlarmEnabledToggle: View {
    @Environment(ClockDisplaySettings.self) private var settings
    @Environment(\.locale) private var locale
    @Environment(\.appTheme) private var theme
    let hour: Int
    let minute: Int
    let isEnabled: Bool
    let isUpdating: Bool
    let onEnabledChange: @MainActor @Sendable (Bool) -> Void

    var body: some View {
        let time = ClockTimeDisplay(hour: hour, minute: minute, format: settings.format, locale: locale).text
        HStack {
            if isUpdating {
                ProgressView().accessibilityLabel("Updating alarm")
            }
            Toggle("Alarm enabled", isOn: Binding(
                get: { isEnabled }, set: onEnabledChange
            ))
            .labelsHidden()
            .tint(theme.palette.selection)
            .accessibilityLabel("Alarm at \(time)")
            .accessibilityValue(isEnabled ? "On" : "Off")
        }
    }
}
