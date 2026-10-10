import RealityKit
import SwiftUI
import UIKit

final class ClockRenderView: ARView {
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
    private var glyphBounds: [String: BoundingBox] = [:]
    private var timeSlots: [ModelEntity] = []
    private let digitHeightScale: Float = 1.15
    private let digitGap: Float = 0.14
    private let rowGap: Float = 0.28
    private let isAlarmPreview: Bool
    var contentSafeAreaInsets: UIEdgeInsets = .zero {
        didSet {
            if oldValue != contentSafeAreaInsets { setNeedsLayout() }
        }
    }
    private let clock = Entity()
    private let backdrop = ModelEntity()
    private var theme: AppTheme
    private let placement = Entity()
    private var cameraRestOffset = SIMD3<Float>.zero
    private var angles = SIMD2<Float>.zero
    private var dragOrigin = SIMD2<Float>.zero
    private var velocity = SIMD2<Float>.zero
    private let maximumAngle: Float = .pi / 7
    private var returnLink: CADisplayLink?
    private var lastFrame: CFTimeInterval = 0
    private let camera = PerspectiveCamera()
    private let keyLight = DirectionalLight()
    private let weekdayLight = SpotLight()
    private var lighting: ClockLightingSettings { theme.clock.lighting }
    private var glyphs: [String: ModelEntity] = [:]
    private var displayedTime: String?

    init(theme: AppTheme, isAlarmPreview: Bool = false) {
        self.theme = theme
        self.isAlarmPreview = isAlarmPreview
        super.init(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        renderOptions = [.disableMotionBlur, .disableDepthOfField, .disableCameraGrain]
        isAccessibilityElement = true
        accessibilityTraits = .staticText

        let anchor = AnchorEntity(world: .zero)
        scene.addAnchor(anchor)
        anchor.addChild(placement)
        placement.addChild(clock)
        camera.camera.fieldOfViewInDegrees = 12
        let orbitGesture = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        orbitGesture.delegate = self
        addGestureRecognizer(orbitGesture)
        accessibilityHint = isAlarmPreview
            ? "Drag to change the viewing angle. Release to return to the front view."
            : "Drag horizontally to change the viewing angle. Swipe up to see alarms."
        anchor.addChild(camera)
        anchor.addChild(weekdayLight)
        weekdayLight.isEnabled = false

        placement.addChild(keyLight)
        backdrop.model = ModelComponent(
            mesh: .generatePlane(width: 200, height: 200),
            materials: []
        )
        backdrop.components.set(DynamicLightShadowComponent(castsShadow: false))
        backdrop.position.z = -0.04
        anchor.addChild(backdrop)

        do {
            glyphs = try ClockGlyphAssets.load()
            glyphBounds = glyphs.mapValues { $0.visualBounds(relativeTo: $0) }
        } catch {
            let message = UILabel()
            message.text = "Unable to load sculpted clock assets"
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
            assertionFailure("Numeral asset failed to load: \(error)")
        }
        applyLighting()
        applyNumeralMaterials()
    }

    @available(*, unavailable)
    required init(frame frameRect: CGRect) { fatalError("Use init(theme:)") }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(theme:)") }

    func applyTheme(_ theme: AppTheme) {
        guard self.theme != theme else { return }
        self.theme = theme
        applyLighting()
        applyNumeralMaterials()
    }

    private func applyLighting() {
        let settings = theme.clock.lighting
        keyLight.light.color = UIColor(theme.clock.lightColor)
        keyLight.light.intensity = Float(settings.strength)
        keyLight.shadow = theme.clock.shadow.map {
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
              cameraRestOffset.z > 0, !timeSlots.isEmpty else {
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

        let clockBounds = clock.visualBounds(relativeTo: nil)
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

    private func applyNumeralMaterials() {
        let appearance = theme.clock
        let material = appearance.numeralMaterial()
        for glyph in glyphs.values { glyph.model?.materials = [material] }
        for case let glyph as ModelEntity in clock.children { glyph.model?.materials = [material] }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }
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
              let firstDigit = timeSlots.first else { return }
        let firstBounds = firstDigit.visualBounds(relativeTo: nil)
        let clockBounds = clock.visualBounds(relativeTo: nil)
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
        let orbit = simd_quatf(angle: angles.x, axis: [0, 1, 0])
            * simd_quatf(angle: angles.y, axis: [1, 0, 0])
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
        if window == nil {
            stopReturn()
            angles = .zero
            applyViewingAngle()
        }
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if isAlarmPreview { return true }
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: self)
        return abs(velocity.x) > abs(velocity.y)
    }

    @objc private func pan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            stopReturn()
            onOrbitBegan?()
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
                onOrbitSettled?()
            } else {
                lastFrame = 0
                let link = CADisplayLink(target: self, selector: #selector(returnToCenter(_:)))
                link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
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
            onOrbitSettled?()
        }
    }

    private func stopReturn() {
        returnLink?.invalidate()
        returnLink = nil
        velocity = .zero
    }

    func show(date: Date) {
        let components = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: date)
        let time = AlarmTimeText.text(hour: components.hour ?? 0, minute: components.minute ?? 0)
        accessibilityLabel = "Time, \(time)"
        show(time: time)
    }

    func showAlarm(time: String) {
        accessibilityLabel = "Alarm time, \(time)"
        show(time: time)
    }

    private func show(time: String) {
        guard time != displayedTime, !glyphs.isEmpty else { return }
        let characters = Array(time.filter(\.isNumber))
        guard characters.count == 4 else { return }
        let previous = Array((displayedTime ?? "").filter(\.isNumber))
        displayedTime = time
        // Four persistent slots: hours above minutes, with aligned digit columns.
        while timeSlots.count < characters.count {
            let slot = ModelEntity()
            clock.addChild(slot)
            timeSlots.append(slot)
        }
        let digitBounds = "0123456789".compactMap { glyphBounds[String($0)] }
        let columnWidth = digitBounds.map(\.extents.x).max() ?? 1.6
        let rowHeight = (digitBounds.map(\.extents.y).max() ?? 3.712) * digitHeightScale
        for (index, character) in characters.enumerated() {
            let key = String(character)
            guard let prototype = glyphs[key], let bounds = glyphBounds[key] else { continue }
            let glyph = timeSlots[index]
            if index >= previous.count || previous[index] != character {
                glyph.model = prototype.model
            }
            let columnCenter = (index.isMultiple(of: 2) ? -1 : Float(1)) * (columnWidth + digitGap) / 2
            let rowCenter = (index < 2 ? 1 : Float(-1)) * (rowHeight + rowGap) / 2
            glyph.scale = [1, digitHeightScale, 1]
            glyph.position = [columnCenter - bounds.center.x,
                              rowCenter - bounds.center.y * digitHeightScale, 0]
        }
        clock.scale = SIMD3(repeating: min(1, 3.8 / (2 * columnWidth + digitGap)))
        updateWeekdayAnchor()
        applyWeekdayLighting()
    }

}
