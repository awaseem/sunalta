import RealityKit
import SwiftUI
import UIKit

struct ClockAppearance {
    let numeralColor: UIColor
    let ambientIntensityExponent: Float

    init(colorScheme: ColorScheme) {
        switch colorScheme {
        case .dark:
            numeralColor = UIColor(red: 234 / 255, green: 231 / 255, blue: 225 / 255, alpha: 1)
            ambientIntensityExponent = -2
        default:
            numeralColor = UIColor(white: 0.16, alpha: 1)
            ambientIntensityExponent = -1
        }
    }

    func numeralMaterial(shimmer: Double) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: numeralColor)
        material.metallic = .init(floatLiteral: 0)
        let amount = Float(min(max(shimmer, 0), 1))
        // Match the sharp model's glossy plastic at the default shimmer (0.6).
        material.roughness = .init(floatLiteral: max(0.04, 0.4 - amount * 0.4))
        material.clearcoat = .init(floatLiteral: 0.8)
        material.clearcoatRoughness = .init(floatLiteral: 0.08)
        return material
    }

    func backdropMaterial(color: UIColor) -> UnlitMaterial {
        var material = UnlitMaterial(applyPostProcessToneMap: false)
        material.color = .init(tint: color)
        return material
    }
}
