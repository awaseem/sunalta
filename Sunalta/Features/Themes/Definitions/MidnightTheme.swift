import SwiftUI

extension AppTheme {
    static let midnight = AppTheme(
        id: "midnight",
        name: "Midnight",
        colorScheme: .dark,
        appIconName: "AppIconMidnight",
        palette: .midnight,
        clock: ClockAppearance(
            numeralColor: Color(white: 0.78),
            roughness: 0.32,
            clearcoat: 0.15,
            clearcoatRoughness: 0.3,
            lighting: ClockLightingSettings(
                direction: 0.36, tilt: 50.24, strength: 750, fill: -1.7
            )
        ),
        weekday: ClockWeekdayAppearance(
            glow: ClockWeekdayGlowSettings(
                color: ThemePalette.midnightAccent,
                halo: 0.1,
                brightness: 350,
                spread: 52,
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
