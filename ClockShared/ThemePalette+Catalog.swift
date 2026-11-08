import SwiftUI

extension ThemePalette {
    static let midnightAccent = Color.Resolved(red: 1, green: 0.74, blue: 0.04)

    static let white = ThemePalette(
        background: .white,
        foreground: .black,
        selection: Color(red: 1, green: 0.08, blue: 0.16)
    )

    static let midnight = ThemePalette(
        background: Color(red: 16 / 255, green: 17 / 255, blue: 20 / 255),
        foreground: .white,
        selection: Color(midnightAccent),
        surface: .white.opacity(0.07)
    )

    static let grass = ThemePalette(
        background: Color(red: 0.96, green: 0.95, blue: 0.90),
        foreground: Color(red: 0.12, green: 0.20, blue: 0.08),
        selection: Color(red: 0.45, green: 0.29, blue: 0.18),
        control: Color(red: 0.16, green: 0.29, blue: 0.09),
        onControl: .white,
        surface: Color(red: 0.20, green: 0.32, blue: 0.12).opacity(0.07)
    )

    static func resolve(id: String) -> ThemePalette {
        switch id {
        case "midnight": .midnight
        case "grass": .grass
        default: .white
        }
    }
}
