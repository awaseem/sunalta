import SwiftUI

/// Only customized values are stored, allowing untouched values to follow the authored theme.
struct ThemeAdjustments: Codable, Equatable {
    var background: Color.Resolved?
    var lighting: ClockLightingSettings?
    var shimmer: Double?
    var weekday: ClockWeekdayAdjustments?

    func applying(to theme: AppTheme) -> AppTheme {
        // Preserve every authored capability, including ones added after these adjustments.
        var adjusted = theme
        if let background { adjusted.palette.background = Color(background) }
        if let lighting { adjusted.clock.lighting = lighting }
        if let shimmer {
            adjusted.clock.roughness = max(0.04, 0.4 - Float(min(max(shimmer, 0), 1)) * 0.4)
        }
        if let weekday { adjusted.weekday = weekday.applying(to: theme.weekday) }
        return adjusted
    }
}
