import SwiftUI
import WidgetKit

struct SmallClockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: ClockWidgetPreferences.kind, provider: SmallClockProvider()) { entry in
            SmallClockWidgetView(date: entry.date, preferences: entry.preferences)
        }
        .configurationDisplayName("Clock")
        .description("A sculpted clock that follows your app's theme and time format.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

#Preview("White", as: .systemSmall) {
    SmallClockWidget()
} timeline: {
    SmallClockEntry(date: .now)
}

#Preview("Midnight", as: .systemSmall) {
    SmallClockWidget()
} timeline: {
    SmallClockEntry(date: .now, preferences: .init(themeID: "midnight", timeFormat: .twelveHour))
}

#Preview("Grass", as: .systemSmall) {
    SmallClockWidget()
} timeline: {
    SmallClockEntry(date: .now, preferences: .init(themeID: "grass"))
}
