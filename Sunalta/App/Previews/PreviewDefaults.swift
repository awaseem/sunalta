import Foundation

/// Each preview starts from explicit preferences and never reads or writes the installed app's suite.
enum PreviewDefaults {
    static func make(timeFormat: ClockTimeFormat = .twentyFourHour) -> UserDefaults {
        guard let defaults = UserDefaults(suiteName: "ClockPreview.\(UUID().uuidString)") else {
            fatalError("Couldn't create isolated preview preferences")
        }
        defaults.register(defaults: [
            "clockTimeFormat": timeFormat.rawValue,
            "showClockPeriod": true,
            "selectedThemeID": "white"
        ])
        return defaults
    }
}
