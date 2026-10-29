import SwiftUI

struct AlarmTimeLabel: View {
    @Environment(ClockDisplaySettings.self) private var settings
    @Environment(\.locale) private var locale
    let hour: Int
    let minute: Int

    var body: some View {
        Text(ClockTimeDisplay(hour: hour, minute: minute, format: settings.format, locale: locale).text)
            .font(.largeTitle)
            .fontDesign(.rounded)
            .monospacedDigit()
    }
}
