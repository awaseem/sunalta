import RealityKit
import SwiftUI
import UIKit

struct ClockAppearance {
    let numeralColor: UIColor
    let ambientIntensityExponent: Float
    let numeralSurface: ClockSurface

    init(colorScheme: ColorScheme) {
        switch colorScheme {
        case .dark:
            numeralColor = UIColor(white: 0.92, alpha: 1)
            numeralSurface = .hangarConcrete
            ambientIntensityExponent = -2
        default:
            numeralColor = UIColor(white: 0.16, alpha: 1)
            numeralSurface = .hangarConcrete
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

    func texturedNumeralMaterial(textures: ClockSurfaceTextures) -> PhysicallyBasedMaterial {
        var material = numeralMaterial
        // Each theme uses its selected material's original color.
        material.baseColor = .init(tint: .white, texture: .init(textures.color))
        material.normal = .init(texture: .init(textures.normal))
        material.roughness = .init(texture: .init(textures.roughness))
        material.ambientOcclusion = .init(texture: .init(textures.ambientOcclusion))
        // Magnify the pores around the UV center so the grain reads at phone size.
        material.textureCoordinateTransform = .init(offset: [0.175, 0.175], scale: [0.65, 0.65])
        return material
    }

    func backdropMaterial(color: UIColor) -> UnlitMaterial {
        var material = UnlitMaterial(applyPostProcessToneMap: false)
        material.color = .init(tint: color)
        return material
    }
}
