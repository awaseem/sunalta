import RealityKit
import SwiftUI
import UIKit

struct ClockAppearance: Equatable {
    let numeralColor: Color
    let lightColor: Color
    let ambientIntensityExponent: Float
    var roughness: Float
    let clearcoat: Float
    let clearcoatRoughness: Float
    var lighting: ClockLightingSettings
    let shadow: ClockShadowSettings?

    func numeralMaterial() -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(numeralColor))
        material.metallic = .init(floatLiteral: 0)
        material.roughness = .init(floatLiteral: roughness)
        material.clearcoat = .init(floatLiteral: clearcoat)
        material.clearcoatRoughness = .init(floatLiteral: clearcoatRoughness)
        return material
    }

    func backdropMaterial(color: UIColor) -> UnlitMaterial {
        var material = UnlitMaterial(applyPostProcessToneMap: false)
        material.color = .init(tint: color)
        return material
    }
}
