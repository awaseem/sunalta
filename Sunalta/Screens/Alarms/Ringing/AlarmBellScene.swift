import Foundation
import RealityKit
import SwiftUI

/// Owns the bell's authored pivots and animation resources for one visible screen.
@MainActor
final class AlarmBellScene {
    let root = Entity()
    private let model: Entity
    private let subject = Entity()
    private let studio = Entity()
    private let keyLight = DirectionalLight()
    private var orbit = ClockOrbitMotion(restingAngles: [.pi / 6, .pi / 12])
    private var isDragging = false
    private var returnTask: Task<Void, Never>?
    private let pivots: [(entity: Entity, rest: Transform, animation: AnimationResource)]
    private var playback: [AnimationPlaybackController] = []
    private var appliedTheme: AppTheme?
    private var bellMaterial: PhysicallyBasedMaterial?
    private var isRinging = false
    private var revealElapsed: TimeInterval = 0
    private var grass: [Entity] = []
    private var grassTime: Float = 0
    static let swingDuration: TimeInterval = 2.4

    /// The renderer's clock keeps decorative bursts aligned with the visible swing.
    var swingTime: TimeInterval? { playback.first?.time }

    init() async throws {
        guard let url = Bundle.main.url(forResource: "RingingBell", withExtension: "usdz") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let model = try await Entity(contentsOf: url)
        self.model = model
        let environment = try await ClockLightingEnvironment.load()
        try Task.checkCancellation()
        pivots = try ["BellSwing", "ClapperSwing"].enumerated().map { index, name in
            guard let pivot = model.findEntity(named: name) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            let rest = pivot.transform
            // Convert the exported scene's front axis into each pivot's local space.
            let axis = normalize(pivot.convert(direction: [0, 0, 1], from: model))
            let frames = (0...144).map { frame in
                let time = Float(frame) / 60
                // One deliberate left-to-right pendulum cycle, with a trailing clapper.
                let amplitude: Float = index == 0 ? -0.38 : 0.26
                let phase: Float = index == 0 ? 0 : -0.35
                let angle = amplitude * sin(time * 2 * .pi / Float(Self.swingDuration) + phase)
                var transform = rest
                transform.rotation = rest.rotation * simd_quatf(angle: angle, axis: axis)
                return transform
            }
            let animation = try AnimationResource.generate(with: SampledAnimation(
                frames: frames, frameInterval: 1 / 60, bindTarget: .transform
            ))
            return (pivot, rest, animation.repeat())
        }
        subject.addChild(model)
        studio.components.set(ImageBasedLightComponent(source: .single(environment)))
        model.components.set(ImageBasedLightReceiverComponent(imageBasedLight: studio))
        subject.addChild(studio)
        subject.addChild(keyLight)
        subject.position.y = -0.18
        root.addChild(subject)
        updateViewingAngle()
    }

    func apply(theme: AppTheme) throws {
        guard theme != appliedTheme else { return }
        if theme.clock.surface == .grass, grass.isEmpty,
           let shell = model.findEntity(named: "BellShell") {
            try addGrass(to: shell)
        } else if theme.clock.surface != .grass {
            grass.forEach { $0.removeFromParent() }
            grass.removeAll()
        }
        appliedTheme = theme
        bellMaterial = theme.clock.numeralMaterial()
        applyRevealMaterial()
        studio.components[ImageBasedLightComponent.self]?.intensityExponent =
            theme.clock.ambientIntensityExponent + Float(theme.clock.lighting.fill)
        keyLight.light.intensity = Float(theme.clock.lighting.strength)
        keyLight.light.color = .init(theme.clock.lightColor)
        updateViewingAngle()
    }

    func setRinging(_ ringing: Bool) {
        guard ringing != isRinging else { return }
        isRinging = ringing
        if ringing {
            playback = pivots.map { $0.entity.playAnimation($0.animation, transitionDuration: 0.15) }
        } else {
            playback.forEach { $0.stop() }
            playback.removeAll()
            for pivot in pivots { pivot.entity.transform = pivot.rest }
        }
    }

    func advanceReveal(by deltaTime: TimeInterval) {
        if isRinging, !grass.isEmpty {
            grassTime += Float(min(deltaTime, 1 / 15))
            updateGrass()
        }
        let duration = ClockEntranceAnimation.fadeDuration
        guard revealElapsed < duration else { return }
        revealElapsed = min(revealElapsed + deltaTime, duration)
        applyRevealMaterial()
    }

    func drag(translation: CGSize, width: CGFloat) {
        if !isDragging {
            returnTask?.cancel()
            returnTask = nil
            orbit.beginDrag()
            isDragging = true
        }
        orbit.drag(translation: [Float(translation.width), Float(translation.height)], width: Float(width))
        updateViewingAngle()
    }

    func endDrag(velocity: CGSize, width: CGFloat, reduceMotion: Bool) {
        guard isDragging else { return }
        isDragging = false
        if reduceMotion {
            resetOrbit()
            return
        }
        orbit.release(velocity: [Float(velocity.width), Float(velocity.height)], width: Float(width))
        returnTask = Task { @MainActor [weak self] in
            var previous = ContinuousClock.now
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(16)) }
                catch { return }
                guard let self else { return }
                let now = ContinuousClock.now
                let elapsed = previous.duration(to: now).components
                previous = now
                let seconds = Float(elapsed.seconds) + Float(elapsed.attoseconds) / 1e18
                let settled = orbit.advance(by: seconds)
                updateViewingAngle()
                if settled {
                    returnTask = nil
                    return
                }
            }
        }
    }

    func resetOrbit() {
        returnTask?.cancel()
        returnTask = nil
        isDragging = false
        orbit.reset()
        updateViewingAngle()
    }

    private func updateViewingAngle() {
        // Rotate the subject so the shared camera can keep the time row stationary.
        root.orientation = orbit.orientation.inverse
        if let appliedTheme {
            let lightOrbit = simd_quatf(angle: -orbit.offset.x * 0.3, axis: [0, 1, 0])
                * simd_quatf(angle: -orbit.offset.y * 0.3, axis: [1, 0, 0])
            keyLight.look(at: .zero, from: lightOrbit.act(appliedTheme.clock.lighting.lightPosition),
                          relativeTo: subject)
        }
    }

    private func apply(material: PhysicallyBasedMaterial, to entity: Entity) {
        guard entity.name != GrassSurface.entityName else { return }
        if var component = entity.components[ModelComponent.self] {
            component.materials = Array(repeating: material, count: max(component.materials.count, 1))
            entity.components.set(component)
        }
        for child in entity.children { apply(material: material, to: child) }
    }

    private func applyRevealMaterial() {
        guard var material = bellMaterial else { return }
        let progress = min(revealElapsed / ClockEntranceAnimation.fadeDuration, 1)
        if progress < 1 {
            let opacity = Float(progress * progress * (3 - 2 * progress))
            material.blending = .transparent(opacity: .init(scale: opacity))
        }
        // Restore the opaque theme material once the entrance finishes.
        apply(material: material, to: model)
        updateGrass()
    }

    private func addGrass(to entity: Entity) throws {
        // Capture the authored hierarchy before attaching the generated meshes.
        let children = Array(entity.children)
        if let component = entity.components[ModelComponent.self] {
            let blades = try GrassSurface.make(on: component.mesh, cacheKey: "bell-\(entity.name)")
            entity.addChild(blades)
            grass.append(blades)
        }
        for child in children { try addGrass(to: child) }
    }

    private func updateGrass() {
        let progress = min(revealElapsed / ClockEntranceAnimation.fadeDuration, 1)
        let opacity = Float(progress * progress * (3 - 2 * progress))
        for blades in grass { GrassSurface.update(blades, time: grassTime, opacity: opacity) }
    }
}
