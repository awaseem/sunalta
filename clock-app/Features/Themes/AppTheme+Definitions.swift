import SwiftUI

extension AppTheme {
    private static let whiteAccent = Color.Resolved(red: 1, green: 0.08, blue: 0.16)
    private static let midnightAccent = Color.Resolved(red: 1, green: 0.85, blue: 0.12)
    private static let grassAccent = Color.Resolved(red: 0.45, green: 0.29, blue: 0.18)

    // Add authored themes here and include them in `available` to expose them in Appearance.
    static let white = AppTheme(
        id: "white",
        name: "White",
        colorScheme: .light,
        palette: ThemePalette(
            background: .white,
            surface: .black.opacity(0.06),
            foreground: .black,
            secondaryForeground: .black.opacity(0.6),
            control: .black,
            onControl: .white,
            selection: Color(whiteAccent),
            separator: .black.opacity(0.15),
            error: .red
        ),
        clock: ClockAppearance(
            numeralColor: .black,
            lightColor: .white,
            ambientIntensityExponent: -1,
            roughness: 0.16,
            clearcoat: 0.8,
            clearcoatRoughness: 0.08,
            lighting: ClockLightingSettings(
                direction: 0.36364316940307617, tilt: 50.24, strength: 2600, fill: 0
            ),
            // Preserve the current sculpted shading without casting a backdrop shadow.
            shadow: nil
        ),
        panelShadow: ThemeShadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6),
        weekday: ClockWeekdayAppearance(
            size: 40.16969585418701,
            weight: .medium,
            glow: ClockWeekdayGlowSettings(
                color: whiteAccent,
                halo: 0.09848485141992569,
                brightness: 3012.121081352234,
                spread: 60,
                direction: 20.36363124847412,
                reach: 5.518181622028351
            )
        ),
        clockFlyby: .bird
    )

    static let midnight = AppTheme(
        id: "midnight",
        name: "Midnight",
        colorScheme: .dark,
        palette: ThemePalette(
            background: Color(red: 16 / 255, green: 17 / 255, blue: 20 / 255),
            surface: .white.opacity(0.07),
            foreground: .white,
            secondaryForeground: .white.opacity(0.6),
            control: .white,
            onControl: Color(red: 16 / 255, green: 17 / 255, blue: 20 / 255),
            selection: Color(midnightAccent),
            separator: .white.opacity(0.15),
            error: .red
        ),
        clock: ClockAppearance(
            numeralColor: .white,
            lightColor: .white,
            ambientIntensityExponent: -1,
            roughness: 0.16,
            clearcoat: 0.8,
            clearcoatRoughness: 0.08,
            lighting: ClockLightingSettings(
                direction: 0.36, tilt: 50.24, strength: 2400, fill: 0.25
            ),
            shadow: nil
        ),
        panelShadow: ThemeShadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 6),
        weekday: ClockWeekdayAppearance(
            size: 40.16969585418701,
            weight: .medium,
            glow: ClockWeekdayGlowSettings(
                color: midnightAccent,
                halo: 0.1,
                brightness: 550,
                spread: 60,
                direction: 20.36,
                reach: 5.52
            )
        ),
        clockFlyby: .bat
    )

    static let grass = AppTheme(
        id: "grass",
        name: "Grass",
        colorScheme: .light,
        palette: ThemePalette(
            background: Color(red: 0.96, green: 0.95, blue: 0.90),
            surface: Color(red: 0.20, green: 0.32, blue: 0.12).opacity(0.07),
            foreground: Color(red: 0.12, green: 0.20, blue: 0.08),
            secondaryForeground: Color(red: 0.12, green: 0.20, blue: 0.08).opacity(0.6),
            control: Color(red: 0.16, green: 0.29, blue: 0.09),
            onControl: .white,
            selection: Color(grassAccent),
            separator: Color(red: 0.16, green: 0.29, blue: 0.09).opacity(0.15),
            error: .red
        ),
        clock: ClockAppearance(
            numeralColor: Color(red: 0.17, green: 0.29, blue: 0.07),
            lightColor: .white,
            ambientIntensityExponent: 0,
            roughness: 0.95,
            clearcoat: 0,
            clearcoatRoughness: 1,
            lighting: ClockLightingSettings(direction: 15, tilt: 45, strength: 1900, fill: 0.3),
            shadow: nil,
            surface: .grass,
            flybyTint: Color(red: 1, green: 0.32, blue: 0.62)
        ),
        panelShadow: ThemeShadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 6),
        weekday: ClockWeekdayAppearance(
            size: 40.16969585418701,
            weight: .medium,
            glow: ClockWeekdayGlowSettings(
                color: grassAccent,
                halo: 0, brightness: 0, spread: 60, direction: 20.36, reach: 5.52
            )
        ),
        clockFlyby: .butterfly
    )

    static let available: [AppTheme] = [.white, .midnight, .grass]
    static let defaultTheme = white

    static func resolve(id: String?) -> AppTheme {
        available.first { $0.id == id } ?? defaultTheme
    }
}
