import RealityKit
import UIKit

/// Reuses the glyph meshes to draw their projected silhouettes on a flat wall.
/// Opaque, unlit colors avoid dark seams where projected triangles overlap.
@MainActor
final class ClockShadowLayer {
    let root = Entity()
    private let counterRotation = Entity()
    private var shadows: [ObjectIdentifier: ModelEntity] = [:]
    private var material = UnlitMaterial(applyPostProcessToneMap: false)
    private var appliedColor: UIColor?

    init() {
        root.addChild(counterRotation)
        material.faceCulling = .none
    }

    func update(settings: ClockLightingSettings, background: UIColor) {
        root.isEnabled = settings.shadowsEnabled && settings.shadowDarkness > 0
        let projection = ClockShadowProjection(direction: settings.direction, length: settings.shadowLength)
        root.transform = Transform(scale: projection.scale, rotation: projection.rotation,
                                   translation: projection.position)
        counterRotation.orientation = projection.counterRotation

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        background.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let remaining = CGFloat(1 - settings.shadowDarkness)
        let color = UIColor(red: red * remaining, green: green * remaining,
                            blue: blue * remaining, alpha: 1)
        guard appliedColor != color else { return }
        appliedColor = color
        material.color = .init(tint: color)
        for shadow in shadows.values { shadow.model?.materials = [material] }
    }

    func synchronize(_ sources: [ModelEntity], relativeTo parent: Entity) {
        let activeIDs = Set(sources.map(ObjectIdentifier.init))
        for id in Array(shadows.keys) where !activeIDs.contains(id) {
            shadows.removeValue(forKey: id)?.removeFromParent()
        }
        for source in sources {
            let id = ObjectIdentifier(source)
            let shadow: ModelEntity
            if let existing = shadows[id] {
                shadow = existing
            } else {
                shadow = ModelEntity()
                shadow.components.set(DynamicLightShadowComponent(castsShadow: false))
                counterRotation.addChild(shadow)
                shadows[id] = shadow
            }
            shadow.model = source.model
            shadow.model?.materials = [material]
            shadow.transform = Transform(matrix: source.transformMatrix(relativeTo: parent))
        }
    }
}
