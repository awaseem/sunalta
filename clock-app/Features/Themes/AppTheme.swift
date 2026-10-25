import SwiftUI

/// The shared configuration contract for every theme, independent of device appearance.
/// Add new capabilities here with defaults, then opt into them in a theme definition.
struct AppTheme: Identifiable, Equatable {
    let id: String
    let name: String
    /// Used only to match native controls and system presentation to the theme.
    let colorScheme: ColorScheme
    /// Asset catalog name; nil uses the primary (White) app icon.
    let appIconName: String?
    var palette: ThemePalette
    var clock: ClockAppearance
    let panelShadow: ThemeShadow
    var weekday: ClockWeekdayAppearance
    var clockFlyby: ClockFlybyKind
    var audio: ClockAudioConfiguration

    init(
        id: String,
        name: String,
        colorScheme: ColorScheme,
        appIconName: String? = nil,
        palette: ThemePalette,
        clock: ClockAppearance? = nil,
        panelShadow: ThemeShadow? = nil,
        weekday: ClockWeekdayAppearance = .init(),
        clockFlyby: ClockFlybyKind = .none,
        audio: ClockAudioConfiguration = .init()
    ) {
        self.id = id
        self.name = name
        self.colorScheme = colorScheme
        self.appIconName = appIconName
        self.palette = palette
        self.clock = clock ?? ClockAppearance(numeralColor: palette.foreground)
        self.panelShadow = panelShadow ?? ThemeShadow(
            color: .black.opacity(colorScheme == .dark ? 0.35 : 0.12)
        )
        self.weekday = weekday
        self.clockFlyby = clockFlyby
        self.audio = audio
    }
}
