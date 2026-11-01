import Foundation

/// The widget receives presentation preferences only; the alarm store stays in the app.
nonisolated struct ClockWidgetPreferences: Codable, Equatable {
    static let kind = "SmallClockWidget"
    static let appGroup = "group.dev.ambitionsoftware.sunalta"
    static let clockURL = URL(string: "sunalta://clock")

    var themeID = "white"
    var timeFormat: ClockTimeFormat = .twentyFourHour
    var showsPeriod = true
}
