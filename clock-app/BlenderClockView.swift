import RealityKit
import SwiftUI
import UIKit

/// Renders the original Blender vertices and corner normals, without substituting a font.
struct BlenderClockView: UIViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    let date: Date

    func makeUIView(context: Context) -> ClockRenderView {
        ClockRenderView(colorScheme: colorScheme)
    }

    func updateUIView(_ view: ClockRenderView, context: Context) {
        view.applyAppearance(colorScheme)
        let components = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: date)
        let time = String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
        view.show(time: time)
        view.accessibilityLabel = "Time, \(time)"
    }
}

final class ClockRenderView: ARView {
    private let clock = Entity()
    private let backdrop = ModelEntity()
    private var appliedColorScheme: ColorScheme?
    private let placement = Entity()
    private var cameraRestOffset = SIMD3<Float>.zero
    private var angles = SIMD2<Float>.zero
    private var dragOrigin = SIMD2<Float>.zero
    private var velocity = SIMD2<Float>.zero
    private let maximumAngle: Float = .pi / 7
    private var returnLink: CADisplayLink?
    private var lastFrame: CFTimeInterval = 0
    private let camera = PerspectiveCamera()
    private var glyphs: [Character: ModelEntity] = [:]
    private var displayedTime: String?

    init(colorScheme: ColorScheme) {
        super.init(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        renderOptions = [.disableMotionBlur, .disableDepthOfField, .disableCameraGrain]
        isAccessibilityElement = true
        accessibilityTraits = .staticText

        let anchor = AnchorEntity(world: .zero)
        scene.addAnchor(anchor)
        anchor.addChild(placement)
        placement.addChild(clock)
        // Stretch the numeral set vertically without changing width or depth.
        clock.scale.y = 1.25
        // Face the camera directly; a narrow field of view minimizes perspective.
        camera.camera.fieldOfViewInDegrees = 12
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(pan(_:))))
        accessibilityHint = "Drag to change the viewing angle; release to return to the front view"
        anchor.addChild(camera)

        // Light and geometry stay in world space. Only the camera orbits,
        // so highlights and cast shadows stay tied to the same light source.
        let key = DirectionalLight()
        key.light.intensity = 2600
        key.light.color = .white
        key.look(at: .zero, from: [4, 6, 6], relativeTo: nil)
        key.shadow = .init(
            shadowProjection: .fixed(zNear: 0.1, zFar: 30, orthographicScale: 10),
            depthBias: 0.1
        )
        placement.addChild(key)
        backdrop.model = ModelComponent(
            mesh: .generatePlane(width: 200, height: 200),
            materials: []
        )
        backdrop.components.set(DynamicLightShadowComponent(castsShadow: false))
        backdrop.position.z = -0.04
        anchor.addChild(backdrop)

        do {
            glyphs = try Self.loadGlyphs()
        } catch {
            let message = UILabel()
            message.text = "Unable to load Blender numerals"
            message.textColor = .label
            message.textAlignment = .center
            message.numberOfLines = 0
            message.translatesAutoresizingMaskIntoConstraints = false
            addSubview(message)
            NSLayoutConstraint.activate([
                message.centerXAnchor.constraint(equalTo: centerXAnchor),
                message.centerYAnchor.constraint(equalTo: centerYAnchor),
                message.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -32)
            ])
            assertionFailure("Numeral asset failed to load: \(error)")
        }
        applyAppearance(colorScheme)
    }

    @available(*, unavailable)
    required init(frame frameRect: CGRect) { fatalError("Use init(colorScheme:)") }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(colorScheme:)") }

    func applyAppearance(_ colorScheme: ColorScheme) {
        guard appliedColorScheme != colorScheme else { return }
        appliedColorScheme = colorScheme
        let appearance = ClockAppearance(colorScheme: colorScheme)
        environment.background = .color(appearance.backdropColor)
        environment.lighting.intensityExponent = appearance.ambientIntensityExponent
        backdrop.model?.materials = [appearance.backdropMaterial]

        // Update both the visible digits and prototypes used by the next minute.
        let material = appearance.numeralMaterial
        for glyph in glyphs.values {
            glyph.model?.materials = [material]
        }
        for case let glyph as ModelEntity in clock.children {
            glyph.model?.materials = [material]
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }
        let aspect = Float(bounds.width / bounds.height)
        let visibleHeight = max(12.3, 7.0 / aspect)
        let distance = visibleHeight / (2 * tan(Float(6 * Double.pi / 180))) + 0.6565
        // Orbit about the clock's center while retaining its screen position
        // in the top third. No glyph translation or rotation is applied.
        let usableHeight = bounds.height - safeAreaInsets.top - safeAreaInsets.bottom
        let centerFromTop = safeAreaInsets.top + usableHeight / 6
        let centerY = visibleHeight * Float(0.5 - centerFromTop / bounds.height)
        placement.position = [0, centerY, 0]
        cameraRestOffset = [0, -centerY, distance]
        applyViewingAngle()
    }

    private func applyViewingAngle() {
        let orbit = simd_quatf(angle: angles.x, axis: [0, 1, 0])
            * simd_quatf(angle: angles.y, axis: [1, 0, 0])
        camera.orientation = orbit
        camera.position = placement.position + orbit.act(cameraRestOffset)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            stopReturn()
            angles = .zero
            applyViewingAngle()
        }
    }

    @objc private func pan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            stopReturn()
            dragOrigin = angles
        case .changed:
            let translation = recognizer.translation(in: self)
            let sensitivity = maximumAngle / Float(max(bounds.width * 0.45, 1))
            let proposed = dragOrigin + SIMD2(-Float(translation.x), Float(translation.y)) * sensitivity
            angles = simd_clamp(proposed, SIMD2(repeating: -maximumAngle), SIMD2(repeating: maximumAngle))
            applyViewingAngle()
        case .ended, .cancelled, .failed:
            let speed = recognizer.velocity(in: self)
            let sensitivity = maximumAngle / Float(max(bounds.width * 0.45, 1))
            velocity = simd_clamp(
                SIMD2(-Float(speed.x), Float(speed.y)) * sensitivity,
                SIMD2(repeating: -1.5), SIMD2(repeating: 1.5)
            )
            if UIAccessibility.isReduceMotionEnabled {
                angles = .zero
                applyViewingAngle()
            } else {
                lastFrame = 0
                let link = CADisplayLink(target: self, selector: #selector(returnToCenter(_:)))
                link.add(to: .main, forMode: .common)
                returnLink = link
            }

        default:
            break
        }
    }

    @objc private func returnToCenter(_ link: CADisplayLink) {
        let elapsed = lastFrame == 0 ? link.duration : link.timestamp - lastFrame
        lastFrame = link.timestamp
        // Small integration steps keep the spring stable at any refresh rate.
        let duration = Float(min(elapsed, 1.0 / 30))
        let steps = max(1, Int(ceil(duration / (1.0 / 240))))
        let dt = duration / Float(steps)
        for _ in 0..<steps {
            velocity += (-150 * angles - 19 * velocity) * dt
            angles += velocity * dt
        }
        applyViewingAngle()
        if simd_length(angles) < 0.001 && simd_length(velocity) < 0.01 {
            angles = .zero
            applyViewingAngle()
            stopReturn()
        }
    }

    private func stopReturn() {
        returnLink?.invalidate()
        returnLink = nil
        velocity = .zero
    }

    func show(time: String) {
        guard time != displayedTime, !glyphs.isEmpty else { return }
        displayedTime = time
        clock.children.removeAll()
        var cursor: Float = 0
        for character in time {
            guard let prototype = glyphs[character] else { continue }
            let glyph = prototype.clone(recursive: true)
            let bounds = glyph.visualBounds(relativeTo: glyph)
            // Pack actual mesh edges, including narrow digits such as 1.
            glyph.position.x = cursor - bounds.min.x
            if character == ":" {
                glyph.position.y = -bounds.center.y
            }
            clock.addChild(glyph)
            cursor += bounds.extents.x + 0.12
        }
        let width = cursor - 0.12
        for glyph in clock.children {
            glyph.position.x -= width / 2
        }
    }

    private static func loadGlyphs() throws -> [Character: ModelEntity] {
        struct MeshData: Decodable {
            let positions: [[Float]]
            let normals: [[Float]]
            let indices: [UInt32]
        }
        guard let url = Bundle.main.url(forResource: "Numerals", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try JSONDecoder().decode([String: MeshData].self, from: Data(contentsOf: url))
        var result: [Character: ModelEntity] = [:]
        for character in "0123456789:" {
            guard let source = data[String(character)],
                  source.positions.count == source.normals.count,
                  source.positions.allSatisfy({ $0.count == 3 }),
                  source.normals.allSatisfy({ $0.count == 3 }),
                  source.indices.allSatisfy({ Int($0) < source.positions.count }) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            var descriptor = MeshDescriptor(name: "Blender \(character)")
            descriptor.positions = MeshBuffers.Positions(source.positions.map { SIMD3($0[0], $0[1], $0[2]) })
            descriptor.normals = MeshBuffers.Normals(source.normals.map { SIMD3($0[0], $0[1], $0[2]) })
            descriptor.primitives = .triangles(source.indices)
            let mesh = try MeshResource.generate(from: [descriptor])
            result[character] = ModelEntity(mesh: mesh, materials: [])
        }
        return result
    }
}
