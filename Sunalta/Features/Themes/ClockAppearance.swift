import SwiftUI

/// Shared material and lighting defaults. Themes override only the values they need.
struct ClockAppearance: Equatable {
    var numeralColor: Color
    var lightColor: Color = .white
    var ambientIntensityExponent: Float = -1
    var roughness: Float = 0.16
    var clearcoat: Float = 0.8
    var clearcoatRoughness: Float = 0.08
    var lighting = ClockLightingSettings(direction: 0.36)
    var shadow: ClockShadowSettings?
    var surface: ClockSurface = .plastic
    var flybyTint: Color?
}
