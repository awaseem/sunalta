import SwiftUI

struct AlarmRingingHeader: View {
    @Environment(ClockDisplaySettings.self) private var settings
    @Environment(\.locale) private var locale
    @Environment(\.appTheme) private var theme
    let alarm: AlarmRecord
    // Preserve the display typography while following the user's Dynamic Type size.
    @ScaledMetric(relativeTo: .largeTitle) private var timeFontSize = 84

    var body: some View {
        let time = ClockTimeDisplay(hour: alarm.hour, minute: alarm.minute,
                                    format: settings.format, locale: locale).text
        VStack {
            Text(time)
                .font(.system(size: timeFontSize, design: .rounded))
                .bold()
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
            if !alarm.label.isEmpty {
                Text(alarm.label)
                    .font(.title2)
                    .foregroundStyle(theme.palette.secondaryForeground)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
