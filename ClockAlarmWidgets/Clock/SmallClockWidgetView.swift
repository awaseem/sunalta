import SwiftUI
import WidgetKit

struct SmallClockWidgetView: View {
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    let date: Date
    let preferences: ClockWidgetPreferences

    var body: some View {
        let palette = SmallClockPalette(themeID: preferences.themeID)
        let display = ClockTimeDisplay(
            date: date, format: preferences.timeFormat, calendar: calendar, locale: locale
        )
        let weekdayStyle = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
        ClockWidgetCalendarLayout {
            ClockWidgetFace(digits: display.digits, themeID: palette.assetThemeID)
            HStack(alignment: .firstTextBaseline) {
                Text(date, format: weekdayStyle.weekday(.abbreviated))
                    .font(.system(.title, weight: .medium))
                    .foregroundStyle(palette.weekday)
                Spacer(minLength: 0)
                if preferences.showsPeriod, let period = display.period {
                    Text(period)
                        .font(.caption2.bold())
                        .foregroundStyle(palette.face)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(date.formatted(weekdayStyle.weekday(.wide))), \(display.text)")
        .containerBackground(palette.background, for: .widget)
        .widgetURL(ClockWidgetPreferences.clockURL)
    }
}
