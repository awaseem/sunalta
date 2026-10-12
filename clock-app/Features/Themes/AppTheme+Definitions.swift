import SwiftUI

extension AppTheme {
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
            selection: .black,
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
                color: Color.Resolved(red: 1, green: 0.07999999, blue: 0.16),
                halo: 0.09848485141992569,
                brightness: 3012.121081352234,
                spread: 60,
                direction: 20.36363124847412,
                reach: 5.518181622028351
            )
        ),
        clockFlyby: .bird
    )

    static let available: [AppTheme] = [.white]
    static let defaultTheme = white

    static func resolve(id: String?) -> AppTheme {
        available.first { $0.id == id } ?? defaultTheme
    }
}
