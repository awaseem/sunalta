import RealityKit
import SwiftUI
import UIKit

final class ClockRenderView: ARView {
    var onContentChanged: (() -> Void)?
    var onOrbitBegan: (() -> Void)?
    var onOrbitSettled: (() -> Void)?
    var onWeekdayAnchorChange: ((CGPoint) -> Void)?
    private var weekdayAnchor: CGPoint?
    var weekdayFrame: CGRect = .zero {
        didSet {
            if oldValue != weekdayFrame { applyWeekdayLighting() }
        }
    }
    var previewHeight: CGFloat = 240 {
        didSet { if oldValue != previewHeight { setNeedsLayout() } }
    }
    private let isAlarmPreview: Bool
    var contentSafeAreaInsets: UIEdgeInsets = .zero {
        didSet {
            if oldValue != contentSafeAreaInsets { setNeedsLayout() }
        }
    }
    private let sceneKind: ClockScene
    private var content: (any ClockSceneContent)?
    private var loadTask: Task<Void, Never>?
    private var materialTask: Task<Void, Never>?
    private var materialRevision = 0
    private var displayedDate = Date.now
    private var previewTime: String?
    var isReady: Bool { content != nil && materialTask == nil }
    private let backdrop = ModelEntity()
    private var theme: AppTheme
    private let placement = Entity()
    private var cameraRestOffset = SIMD3<Float>.zero
    private var orbitInteraction: ClockOrbitInteraction?
    private var angles: SIMD2<Float> { orbitInteraction?.motion.offset ?? .zero }
    private let camera = Entity()
    private let keyLight = DirectionalLight()
    private let weekdayLight = SpotLight()
    private var lighting: ClockLightingSettings { theme.clock.lighting }

    init(theme: AppTheme, scene: ClockScene = .numbers, isAlarmPreview: Bool = false) {
        self.theme = theme
        sceneKind = scene
        self.isAlarmPreview = isAlarmPreview
        super.init(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        renderOptions = [.disableMotionBlur, .disableDepthOfField, .disableCameraGrain]
        isAccessibilityElement = true
        accessibilityTraits = .staticText

        let anchor = AnchorEntity(world: .zero)
        self.scene.addAnchor(anchor)
        anchor.addChild(placement)
        if scene == .alarm {
            var projection = OrthographicCameraComponent()
            projection.scaleDirection = .vertical
            projection.scale = 2.05
            camera.components.set(projection)
        } else {
            var projection = PerspectiveCameraComponent()
            projection.fieldOfViewInDegrees = 12
            camera.components.set(projection)
        }
        orbitInteraction = ClockOrbitInteraction(view: self, restingAngles: scene.restingAngles,
                                                 allowsVerticalDrag: isAlarmPreview) { [weak self] _ in
            self?.applyViewingAngle()
        }
        orbitInteraction?.onBegan = { [weak self] in self?.onOrbitBegan?() }
        orbitInteraction?.onSettled = { [weak self] in self?.onOrbitSettled?() }
        accessibilityHint = isAlarmPreview
            ? "Drag to change the viewing angle. Release to return to the front view."
            : scene == .numbers
                ? "Drag horizontally to change the viewing angle. Swipe up to see alarms."
                : "Drag horizontally to change the viewing angle. Release to return to the starting view."
        anchor.addChild(camera)
        anchor.addChild(weekdayLight)
        weekdayLight.isEnabled = false

        placement.addChild(keyLight)
        backdrop.model = ModelComponent(
            mesh: .generatePlane(width: 200, height: 200),
            materials: []
        )
        backdrop.components.set(DynamicLightShadowComponent(castsShadow: false))
        backdrop.position.z = scene.backdropDepth
        anchor.addChild(backdrop)

        applyLighting()
        loadTask = Task { @MainActor [weak self] in
            do {
                let content = try await scene.load()
                try Task.checkCancellation()
                guard let self else { return }
                self.content = content
                placement.addChild(content.root)
                updateTime()
                applyMaterials()
                setNeedsLayout()
            } catch is CancellationError {
                // Offscreen pages release their renderer, including any pending load.
            } catch {
                guard !Task.isCancelled else { return }
                self?.showLoadError(error)
            }
        }
    }

    private func showLoadError(_ error: Error) {
        let message = UILabel()
        message.text = "Unable to load clock"
        message.textColor = UIColor(theme.palette.foreground)
        message.textAlignment = .center
        message.numberOfLines = 0
        message.translatesAutoresizingMaskIntoConstraints = false
        addSubview(message)
        NSLayoutConstraint.activate([
            message.centerXAnchor.constraint(equalTo: centerXAnchor),
            message.centerYAnchor.constraint(equalTo: centerYAnchor),
            message.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -32)
        ])
        assertionFailure("Clock scene failed to load: \(error)")
    }

    @available(*, unavailable)
    required init(frame frameRect: CGRect) { fatalError("Use init(theme:)") }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(theme:)") }

    func applyTheme(_ theme: AppTheme) {
        guard self.theme != theme else { return }
        self.theme = theme
        applyLighting()
        applyMaterials()
    }

    private func applyLighting() {
        let settings = theme.clock.lighting
        keyLight.light.color = UIColor(theme.clock.lightColor)
        keyLight.light.intensity = Float(settings.strength)
        keyLight.shadow = sceneKind == .alarm ? nil : theme.clock.shadow.map {
            DirectionalLightComponent.Shadow(
                shadowProjection: .automatic(maximumDistance: $0.maximumDistance), depthBias: $0.depthBias
            )
        }
        let appearance = theme.clock
        environment.lighting.intensityExponent = appearance.ambientIntensityExponent + Float(settings.fill)
        let background = UIColor(theme.palette.background)
        environment.background = .color(background)
        backdrop.model?.materials = [appearance.backdropMaterial(color: background)]
        applyInteractionLighting()
        applyWeekdayLighting()
    }

    private func applyWeekdayLighting() {
        guard !isAlarmPreview, !weekdayFrame.isEmpty, bounds.height > 0,
              cameraRestOffset.z > 0, let content = content as? NumeralClockScene,
              content.firstDigit != nil else {
            weekdayLight.isEnabled = false
            return
        }
        let glow = theme.weekday.glow
        weekdayLight.isEnabled = glow.brightness > 0
        weekdayLight.light = SpotLightComponent(
            // The numeral meshes are several scene meters tall; scale the accent accordingly.
            color: UIColor(Color(glow.color)), intensity: Float(glow.brightness * 500),
            innerAngleInDegrees: Float(glow.spread * 0.35),
            outerAngleInDegrees: Float(glow.spread), attenuationRadius: Float(glow.reach)
        )

        let clockBounds = content.root.visualBounds(relativeTo: nil)
        let depth = max(cameraRestOffset.z - clockBounds.max.z - 2, 0.1)
        let focalLength = Float(bounds.height) / (2 * tan(Float(6 * Double.pi / 180)))
        let source = SIMD3<Float>(
            Float(weekdayFrame.midX - bounds.midX) * depth / focalLength,
            Float(bounds.midY - weekdayFrame.midY) * depth / focalLength,
            -depth
        )
        let direction = Float(glow.direction * .pi / 180)
        // Aim upward and back toward the numeral faces, with a soft cone falloff.
        let target = source + SIMD3<Float>(sin(direction), cos(direction), -1.5)
        weekdayLight.look(at: camera.convert(position: target, to: nil),
                          from: camera.convert(position: source, to: nil), relativeTo: nil)
    }

    private func applyMaterials() {
        guard let content else { return }
        materialTask?.cancel()
        materialRevision += 1
        let revision = materialRevision
        let theme = theme
        materialTask = Task { @MainActor [weak self] in
            do {
                try await content.apply(theme: theme)
                try Task.checkCancellation()
                guard let self, materialRevision == revision else { return }
                materialTask = nil
                onContentChanged?()
            } catch is CancellationError {
                // A newer theme or a released renderer supersedes this work.
            } catch {
                guard let self, materialRevision == revision else { return }
                materialTask = nil
                showLoadError(error)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }
        if sceneKind == .alarm {
            placement.position = .zero
            let aspect = Float(bounds.width / bounds.height)
            let visibleHeight = max(4.1, 3.2 / aspect)
            camera.components[OrthographicCameraComponent.self]?.scale = visibleHeight / 2
            cameraRestOffset = [0, 0, 8]
            applyViewingAngle()
            return
        }
        let aspect = Float(bounds.width / bounds.height)
        // The preview's lit backdrop fills the entire modal, eliminating color seams.
        let visibleHeight = isAlarmPreview
            ? max(Float(bounds.height / max(previewHeight, 1)) * 10.7, 4.4 / aspect)
            : max(13.8, 4.4 / aspect)
        let distance = visibleHeight / (2 * tan(Float(6 * Double.pi / 180))) + 0.6565
        let topInset = max(safeAreaInsets.top, contentSafeAreaInsets.top)
        let bottomInset = max(safeAreaInsets.bottom, contentSafeAreaInsets.bottom)
        let usableHeight = bounds.height - topInset - bottomInset
        let centerFromTop = isAlarmPreview
            ? topInset + 44 + previewHeight * 0.50
            : topInset + usableHeight * 0.40
        let centerY = visibleHeight * Float(0.5 - centerFromTop / bounds.height)
        placement.position = [0, centerY, 0]
        cameraRestOffset = [0, -centerY, distance]
        applyViewingAngle()
        updateWeekdayAnchor()
        applyWeekdayLighting()
    }

    private func updateWeekdayAnchor() {
        guard !isAlarmPreview, bounds.height > 0, cameraRestOffset.z > 0,
              let content = content as? NumeralClockScene,
              let firstDigit = content.firstDigit else { return }
        let firstBounds = firstDigit.visualBounds(relativeTo: nil)
        let clockBounds = content.root.visualBounds(relativeTo: nil)
        // Project from the resting camera, keeping the label fixed during an orbit.
        let focalLength = Float(bounds.height) / (2 * tan(Float(6 * Double.pi / 180)))
        let leftScale = focalLength / (cameraRestOffset.z - firstBounds.max.z)
        let bottomScale = focalLength / (cameraRestOffset.z - clockBounds.max.z)
        let anchor = CGPoint(
            x: bounds.midX + CGFloat(firstBounds.min.x * leftScale),
            y: bounds.midY - CGFloat(clockBounds.min.y * bottomScale)
        )
        guard anchor != weekdayAnchor else { return }
        weekdayAnchor = anchor
        onWeekdayAnchorChange?(anchor)
    }

    private func applyViewingAngle() {
        let orbit = orbitInteraction?.motion.orientation ?? simd_quatf(angle: 0, axis: [0, 1, 0])
        camera.orientation = orbit
        camera.position = placement.position + orbit.act(cameraRestOffset)
        applyInteractionLighting()
        applyWeekdayLighting()
    }

    private func applyInteractionLighting() {
        var position = lighting.lightPosition
        if angles != .zero && !UIAccessibility.isReduceMotionEnabled {
            // The camera moves opposite the finger. Let the light follow the
            // finger at 30% of that angle, using the same spring on release.
            let maximumAngle = orbitInteraction?.motion.maximumAngle ?? .pi / 7
            let boundedAngles = simd_clamp(angles, SIMD2(repeating: -maximumAngle),
                                          SIMD2(repeating: maximumAngle))
            let lightOrbit = simd_quatf(angle: -boundedAngles.x * 0.3, axis: [0, 1, 0])
                * simd_quatf(angle: -boundedAngles.y * 0.3, axis: [1, 0, 0])
            position = lightOrbit.act(position)
        }
        keyLight.look(at: .zero, from: position, relativeTo: placement)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { orbitInteraction?.reset() }
    }

    func show(date: Date) {
        displayedDate = date
        previewTime = nil
        accessibilityLabel = "Time, \(date.formatted(date: .omitted, time: .shortened))"
        updateTime()
    }

    func showAlarm(time: String) {
        previewTime = time
        accessibilityLabel = "Alarm time, \(time)"
        updateTime()
    }

    private func updateTime() {
        if let previewTime, let content = content as? NumeralClockScene {
            content.show(time: previewTime)
        } else {
            content?.show(date: displayedDate)
        }
        updateWeekdayAnchor()
        applyWeekdayLighting()
    }

    func stop() {
        loadTask?.cancel()
        loadTask = nil
        materialTask?.cancel()
        materialTask = nil
        materialRevision += 1
        orbitInteraction?.reset()
        scene.anchors.removeAll()
        content = nil
    }
}
