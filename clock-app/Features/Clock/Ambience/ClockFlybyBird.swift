import RealityKit

/// One reusable bird in the flock; every instance shares the same cached meshes.
@MainActor
final class ClockFlybyBird {
    let root = Entity()
    private let body: ModelEntity
    private let nearWing: ModelEntity
    private let farWing: ModelEntity

    init(meshes: (body: MeshResource, wing: MeshResource), material: PhysicallyBasedMaterial) {
        body = ModelEntity(mesh: meshes.body, materials: [material])
        nearWing = ModelEntity(mesh: meshes.wing, materials: [material])
        farWing = ModelEntity(mesh: meshes.wing, materials: [material])
        root.components.set(OpacityComponent(opacity: 0))
        for part in [body, nearWing, farWing] {
            part.components.set(DynamicLightShadowComponent(castsShadow: false))
            root.addChild(part)
        }
        nearWing.position = [-0.018, 0.018, 0.048]
        farWing.position = [-0.018, 0.018, -0.048]
        root.isEnabled = false
    }

    func apply(material: PhysicallyBasedMaterial) {
        for part in [body, nearWing, farWing] { part.model?.materials = [material] }
    }

    func update(path: ClockFlybyPath, elapsed: Double, viewport: SIMD2<Float>, cameraDistance: Float) {
        guard elapsed >= 0, elapsed < path.duration else {
            root.isEnabled = false
            return
        }
        root.position = path.position(at: elapsed, viewport: viewport, cameraDistance: cameraDistance)
        root.orientation = path.orientation(at: elapsed, viewport: viewport, cameraDistance: cameraDistance)
        root.components[OpacityComponent.self]?.opacity = path.opacity(at: elapsed)
        let flap = sin(Float(elapsed) * .pi * 2 * 3) * 0.7
        nearWing.orientation = simd_quatf(angle: flap, axis: [1, 0, 0])
        farWing.orientation = simd_quatf(angle: .pi - flap, axis: [1, 0, 0])
        root.isEnabled = true
    }
}
