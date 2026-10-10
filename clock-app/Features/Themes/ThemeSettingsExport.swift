import SwiftUI

/// Includes effective values, so copied settings also capture unmodified theme defaults.
struct ThemeSettingsExport: Encodable {
    let themeID: String
    let themeName: String
    let background: Color.Resolved
    let lighting: ClockLightingSettings
    let shimmer: Double
    let weekday: ClockWeekdayAppearance
}
