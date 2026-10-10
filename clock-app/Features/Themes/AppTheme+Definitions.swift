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
            lighting: ClockLightingSettings(),
            // Preserve the current sculpted shading without casting a backdrop shadow.
            shadow: nil
        ),
        panelShadow: ThemeShadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
    )

    static let available: [AppTheme] = [.white]
    static let defaultTheme = white

    static func resolve(id: String?) -> AppTheme {
        available.first { $0.id == id } ?? defaultTheme
    }
}
