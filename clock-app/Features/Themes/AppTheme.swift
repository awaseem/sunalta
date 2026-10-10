import SwiftUI

/// A complete appearance, independent of the device's light or dark mode.
struct AppTheme: Identifiable, Equatable {
    let id: String
    let name: String
    /// Used only to match native controls and system presentation to the theme.
    let colorScheme: ColorScheme
    let palette: ThemePalette
    let clock: ClockAppearance
    let panelShadow: ThemeShadow
    var weekday = ClockWeekdayAppearance()
    var alarmClockFinish = AlarmClockFinish()
}
