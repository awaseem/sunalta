import RealityKit
import SwiftUI
import UIKit

struct ClockAppearance {
    let numeralColor: UIColor
    let backdropColor: UIColor
    let ambientIntensityExponent: Float

    init(colorScheme: ColorScheme) {
        switch colorScheme {
        case .dark:
            numeralColor = UIColor(white: 0.92, alpha: 1)
            backdropColor = UIColor(white: 0.10, alpha: 1)
            ambientIntensityExponent = -2
        default:
            numeralColor = UIColor(white: 0.16, alpha: 1)
            backdropColor = UIColor(white: 0.82, alpha: 1)
            ambientIntensityExponent = -1
        }
    }

    var numeralMaterial: PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: numeralColor)
        material.metallic = .init(floatLiteral: 0)
        material.roughness = .init(floatLiteral: 0.8)
        return material
    }

    var backdropMaterial: PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: backdropColor)
        material.roughness = .init(floatLiteral: 1)
        return material
    }
}
