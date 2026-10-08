import RealityKit
import SwiftUI
import UIKit

struct ClockAppearance {
    let numeralColor: UIColor
    let ambientIntensityExponent: Float
    let usesSandpaper: Bool

    init(colorScheme: ColorScheme) {
        switch colorScheme {
        case .dark:
            numeralColor = UIColor(white: 0.92, alpha: 1)
            usesSandpaper = false
            ambientIntensityExponent = -2
        default:
            numeralColor = UIColor(white: 0.16, alpha: 1)
            usesSandpaper = true
            ambientIntensityExponent = -1
        }
    }

    func numeralMaterial(shimmer: Double) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: numeralColor)
        material.metallic = .init(floatLiteral: 0)
        let amount = Float(min(max(shimmer, 0), 1))
        material.roughness = .init(floatLiteral: usesSandpaper ? 0.85 - amount * 0.75 : 0.65 - amount * 0.55)
        return material
    }

    func texturedNumeralMaterial(textures: ClockSurfaceTextures, shimmer: Double) -> PhysicallyBasedMaterial {
        var material = numeralMaterial(shimmer: shimmer)
        guard usesSandpaper else { return material }
        material.baseColor = .init(tint: .white, texture: .init(textures.color))
        material.normal = .init(texture: .init(textures.normal))
        return material
    }

    func backdropMaterial(color: UIColor) -> UnlitMaterial {
        var material = UnlitMaterial(applyPostProcessToneMap: false)
        material.color = .init(tint: color)
        return material
    }
}
