import SwiftUI

extension AppTheme {
    private static let grassAccent = Color.Resolved(red: 0.45, green: 0.29, blue: 0.18)

    static let grass = AppTheme(
        id: "grass",
        name: "Grass",
        colorScheme: .light,
        appIconName: "AppIconGrass",
        palette: .grass,
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
            music: ClockSound(fileName: "grass-field.mp3", volume: 0.04),
            flyby: ClockSound(fileName: "butterfly-sounds.wav", volume: 0.16),
            entrance: ClockSound(fileName: "clock-entrance.wav", volume: 0.4)
        )
    )
}
