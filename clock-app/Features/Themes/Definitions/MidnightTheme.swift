import SwiftUI

extension AppTheme {
    private static let midnightAccent = Color.Resolved(red: 1, green: 0.85, blue: 0.12)

    static let midnight = AppTheme(
        id: "midnight",
        name: "Midnight",
        colorScheme: .dark,
        palette: ThemePalette(
            background: Color(red: 16 / 255, green: 17 / 255, blue: 20 / 255),
            foreground: .white,
            selection: Color(midnightAccent),
            surface: .white.opacity(0.07)
        ),
        clock: ClockAppearance(
            numeralColor: .white,
            lighting: ClockLightingSettings(
                direction: 0.36, tilt: 50.24, strength: 2400, fill: 0.25
            )
        ),
        weekday: ClockWeekdayAppearance(
            glow: ClockWeekdayGlowSettings(
                color: midnightAccent,
                halo: 0.1,
                brightness: 550,
                spread: 60,
                direction: 20.36,
                reach: 5.52
            )
        ),
        clockFlyby: .bat,
        audio: ClockAudioConfiguration(
            alarm: .quietOrbit,
            music: ClockSound(fileName: "midnight-street.mp3", volume: 0.25),
            musicLoopDelay: .seconds(10),
            flyby: ClockSound(fileName: "bat-sounds.wav", volume: 0.65),
            entrance: ClockSound(fileName: "clock-entrance.wav", volume: 0.4)
        )
    )
}
