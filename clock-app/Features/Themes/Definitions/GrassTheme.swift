import SwiftUI

extension AppTheme {
    private static let grassAccent = Color.Resolved(red: 0.45, green: 0.29, blue: 0.18)

    static let grass = AppTheme(
        id: "grass",
        name: "Grass",
        colorScheme: .light,
        appIconName: "AppIconGrass",
        palette: ThemePalette(
            background: Color(red: 0.96, green: 0.95, blue: 0.90),
            foreground: Color(red: 0.12, green: 0.20, blue: 0.08),
            selection: Color(grassAccent),
            control: Color(red: 0.16, green: 0.29, blue: 0.09),
            onControl: .white,
            surface: Color(red: 0.20, green: 0.32, blue: 0.12).opacity(0.07)
        ),
        clock: ClockAppearance(
            numeralColor: Color(red: 0.17, green: 0.29, blue: 0.07),
            ambientIntensityExponent: 0,
            roughness: 0.95,
            clearcoat: 0,
            clearcoatRoughness: 1,
            lighting: ClockLightingSettings(direction: 15, tilt: 45, strength: 1900, fill: 0.3),
            surface: .grass,
            flybyTint: Color(red: 1, green: 0.32, blue: 0.62)
        ),
        panelShadow: ThemeShadow(color: .black.opacity(0.1)),
        weekday: ClockWeekdayAppearance(
            glow: ClockWeekdayGlowSettings(
                color: grassAccent,
                halo: 0, brightness: 0, spread: 60, direction: 20.36, reach: 5.52
            )
        ),
        clockFlyby: .butterfly,
        audio: ClockAudioConfiguration(
            alarm: .meadowMorning,
            music: ClockSound(fileName: "grass-field.mp3", volume: 0.25),
            musicLoopDelay: .seconds(10),
            flyby: ClockSound(fileName: "butterfly-sounds.wav", volume: 0.65),
            entrance: ClockSound(fileName: "clock-entrance.wav", volume: 0.4)
        )
    )
}
