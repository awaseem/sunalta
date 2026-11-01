import SwiftUI

struct SettingsClockSection: View {
    @Environment(ClockDisplaySettings.self) private var settings
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading) {
            Text("Clock")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                Toggle("24-Hour Time", isOn: Binding(
                    get: { settings.format == .twentyFourHour },
                    set: { settings.format = $0 ? .twentyFourHour : .twelveHour }
                ))
                .padding(.vertical, 12)
                Divider().overlay(theme.palette.separator)
                Toggle("Show AM/PM", isOn: Binding(
                    get: { settings.format == .twelveHour && settings.showsPeriod },
                    set: { settings.showsPeriod = $0 }
                ))
                .disabled(settings.format == .twentyFourHour)
                .accessibilityHint("Shows AM/PM on the clock face in 12-hour time.")
                .padding(.vertical, 12)
            }
            .tint(theme.palette.selection)
            .padding(.horizontal)
            .background(theme.palette.surface, in: .rect(cornerRadius: 20))
        }
    }
}
