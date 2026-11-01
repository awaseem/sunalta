import Foundation
import Metal
import RealityKit

/// A single batched mesh per object, shared by repeated digits and clock instances.
@MainActor
enum GrassSurface {
    static let entityName = "Grass blades"
    private static var meshes: [String: MeshResource] = [:]
    private static var material: CustomMaterial?

    static func make(on mesh: MeshResource, cacheKey: String) throws -> ModelEntity {
        let blades: MeshResource
        if let cached = meshes[cacheKey] {
            blades = cached
        } else {
            blades = try GrassBladeMesh.generate(on: mesh)
            meshes[cacheKey] = blades
        }
        if material == nil {
            guard let library = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary() else {
                throw CocoaError(.fileReadUnknown)
            }
            var grass = try CustomMaterial(
                surfaceShader: .init(named: "grassSurface", in: library),
                geometryModifier: .init(named: "grassBreeze", in: library),
                lightingModel: .lit
            )
            grass.faceCulling = .none
            grass.custom.value = [0, 1, 0, 0]
            material = grass
        }
        guard let material else { throw CocoaError(.fileReadUnknown) }
        let entity = ModelEntity(mesh: blades, materials: [material])
        entity.name = entityName
        return entity
    }

    static func update(_ entity: Entity, time: Float, opacity: Float = 1) {
        guard var component = entity.components[ModelComponent.self],
              var material = component.materials.first as? CustomMaterial else { return }
        material.custom.value = [time, opacity, 0, 0]
        material.blending = opacity < 1 ? .transparent(opacity: .init(scale: 1)) : .opaque
        component.materials = [material]
        entity.components.set(component)
    }
}
