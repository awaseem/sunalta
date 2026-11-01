import SwiftUI

struct SmallClockPalette {
    let background: Color
    let face: Color
    let weekday: Color
    let assetThemeID: String

    init(themeID: String) {
        switch themeID {
        case "midnight":
            background = Color(red: 16 / 255, green: 17 / 255, blue: 20 / 255)
            face = .white
            weekday = Color(red: 1, green: 0.85, blue: 0.12)
            assetThemeID = "midnight"
        case "grass":
            background = Color(red: 0.96, green: 0.95, blue: 0.90)
            face = Color(red: 0.17, green: 0.29, blue: 0.07)
            weekday = Color(red: 0.45, green: 0.29, blue: 0.18)
            assetThemeID = "grass"
        default:
            background = .white
            face = .black
            weekday = Color(red: 1, green: 0.08, blue: 0.16)
            assetThemeID = "white"
        }
    }
}
