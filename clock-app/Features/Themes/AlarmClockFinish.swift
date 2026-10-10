import Foundation
import RealityKit

/// Authored per theme. Unspecified values follow the main clock's glossy material.
/// Texture names include their extensions and refer to bundled, UV-mapped PBR assets.
struct AlarmClockFinish: Equatable {
    var roughness: Float?
    var metallic: Float?
    var clearcoat: Float?
    var baseColorTexture: String?
    var normalTexture: String?
    var roughnessTexture: String?
    var metallicTexture: String?

    @MainActor
    func material(matching appearance: ClockAppearance) async throws -> PhysicallyBasedMaterial {
        var material = appearance.numeralMaterial()
        if let roughness { material.roughness = .init(floatLiteral: roughness) }
        if let metallic { material.metallic = .init(floatLiteral: metallic) }
        if let clearcoat { material.clearcoat = .init(floatLiteral: clearcoat) }
        if let texture = try await texture(named: baseColorTexture, semantic: .color) {
            // Use the image's colors directly instead of multiplying them by black paint.
            material.baseColor = .init(texture: texture)
        }
        if let texture = try await texture(named: normalTexture, semantic: .normal) {
            material.normal = .init(texture: texture)
        }
        if let texture = try await texture(named: roughnessTexture, semantic: .scalar) {
            material.roughness = .init(scale: roughness ?? 1, texture: texture)
        }
        if let texture = try await texture(named: metallicTexture, semantic: .scalar) {
            material.metallic = .init(scale: metallic ?? 1, texture: texture)
        }
        return material
    }

    @MainActor
    private func texture(named name: String?, semantic: TextureResource.Semantic) async throws
        -> MaterialParameters.Texture? {
        guard let name else { return nil }
        guard let url = Bundle.main.url(forResource: name, withExtension: nil) else {
            throw CocoaError(.fileNoSuchFile)
        }
        let resource = try await TextureResource(
            contentsOf: url, options: .init(semantic: semantic)
        )
        return MaterialParameters.Texture(resource)
    }
}
