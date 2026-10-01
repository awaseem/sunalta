import SwiftUI

struct ClockLightingSettings: Equatable {
    // Match the original light's direction from [4, 6, 6].
    var direction = 56.31
    var shadowLength = 50.24
    var strength = 2600.0
    var fill = 0.0
    var shadowsEnabled = true
    var shadowDarkness = 0.45
    var lightBackground = Color(white: 0.82)
    var darkBackground = Color(white: 0.10)

    func backgroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkBackground : lightBackground
    }

    var lightPosition: SIMD3<Float> {
        let azimuth = direction * .pi / 180
        let tilt = shadowLength * .pi / 180
        return SIMD3(Float(cos(azimuth) * sin(tilt)),
                     Float(sin(azimuth) * sin(tilt)), Float(cos(tilt))) * 10
    }
}
