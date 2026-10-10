import SwiftUI

/// Only customized values are stored, allowing untouched values to follow the authored theme.
struct ThemeAdjustments: Codable, Equatable {
    var background: Color.Resolved?
    var lighting: ClockLightingSettings?
    var shimmer: Double?
    var weekday: ClockWeekdayAdjustments?

    func applying(to theme: AppTheme) -> AppTheme {
        var palette = theme.palette
        if let background { palette.background = Color(background) }
        var clock = theme.clock
        if let lighting { clock.lighting = lighting }
        if let shimmer {
            clock.roughness = max(0.04, 0.4 - Float(min(max(shimmer, 0), 1)) * 0.4)
        }
        return AppTheme(id: theme.id, name: theme.name, colorScheme: theme.colorScheme,
                        palette: palette, clock: clock, panelShadow: theme.panelShadow,
                        weekday: weekday?.applying(to: theme.weekday) ?? theme.weekday,
                        alarmClockFinish: theme.alarmClockFinish)
    }
}
