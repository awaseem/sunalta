import OSLog
import RealityKit
import SwiftUI
import UIKit

final class ClockRenderView: ClockMetalView {
    var onContentChanged: (() -> Void)?
    var onOrbitBegan: (() -> Void)?
    var onOrbitSettled: (() -> Void)?
    var onWeekdayAnchorChange: ((CGPoint) -> Void)?
    var onPeriodAnchorChange: ((CGPoint) -> Void)?
    private var weekdayAnchor: CGPoint?
    private var periodAnchor: CGPoint?
    var weekdayFrame: CGRect = .zero {
        didSet {
            if oldValue != weekdayFrame {
                applyWeekdayLighting()
                requestFrame()
            }
        }
    }
    var previewHeight: CGFloat = 240 {
        didSet { if oldValue != previewHeight { setNeedsLayout() } }
    }
    var previewTopInset: CGFloat = 44 {
        didSet { if oldValue != previewTopInset { setNeedsLayout() } }
    }
    var clockVerticalCenter: CGFloat = 0.4 {
        didSet { if oldValue != clockVerticalCenter { setNeedsLayout() } }
    }
    private let isAlarmPreview: Bool
    private let previewNumeral: String?
    var contentSafeAreaInsets: UIEdgeInsets = .zero {
        didSet {
            if oldValue != contentSafeAreaInsets { setNeedsLayout() }
        }
    }
    private var content: NumeralClockScene?
    private var loadTask: Task<Void, Never>?
    private var materialTask: Task<Void, Never>?
    private var materialRevision = 0
    private var display: ClockTimeDisplay?
    var isReady: Bool { content != nil && materialTask == nil }
    override var isSceneReady: Bool { isReady }
    private let backdrop = ModelEntity()
    private var theme: AppTheme
    private let placement = Entity()
    private var cameraRestOffset = SIMD3<Float>.zero
    private var orbitInteraction: ClockOrbitInteraction?
    private var angles: SIMD2<Float> { orbitInteraction?.motion.offset ?? .zero }
    var entranceAngles = SIMD2<Float>.zero {
        didSet { if oldValue != entranceAngles { applyViewingAngle() } }
    }
    private let camera = Entity()
    private let keyLight = DirectionalLight()
    private let weekdayLight = SpotLight()
    private var lighting: ClockLightingSettings { theme.clock.lighting }
    private var flybys: ClockFlybyController?
    private let audioService: ClockAudioService?
    private let grassBreeze = GrassBreeze()
    var allowsAmbientAnimation = false {
        didSet { if oldValue != allowsAmbientAnimation { updateFlybys() } }
    }

    init(theme: AppTheme, isAlarmPreview: Bool = false, previewNumeral: String? = nil,
         audioService: ClockAudioService? = nil) {
        self.theme = theme
        self.audioService = audioService
        self.isAlarmPreview = isAlarmPreview || previewNumeral != nil
        self.previewNumeral = previewNumeral
        super.init()
        isAccessibilityElement = true
        accessibilityTraits = .staticText

        if let initializationError {
            showLoadError(initializationError)
            return
        }

        let anchor = Entity()
        realityRenderer?.entities.append(anchor)
        anchor.addChild(placement)
        var projection = PerspectiveCameraComponent()
        projection.fieldOfViewInDegrees = 12
        camera.components.set(projection)
        orbitInteraction = ClockOrbitInteraction(view: self, restingAngles: .zero,
                                                 allowsVerticalDrag: isAlarmPreview) { [weak self] _ in
            self?.applyViewingAngle()
        }
        orbitInteraction?.onBegan = { [weak self] in self?.onOrbitBegan?() }
        orbitInteraction?.onSettled = { [weak self] in self?.onOrbitSettled?() }
        accessibilityHint = isAlarmPreview
            ? "Drag to change the viewing angle. Release to return to the front view."
            : "Drag horizontally to change the viewing angle. Swipe up to see alarms."
        anchor.addChild(camera)
        realityRenderer?.activeCamera = camera
        anchor.addChild(weekdayLight)
        weekdayLight.isEnabled = false

        placement.addChild(keyLight)
        backdrop.model = ModelComponent(
            mesh: .generatePlane(width: 200, height: 200),
            materials: []
        )
        backdrop.components.set(DynamicLightShadowComponent(castsShadow: false))
        backdrop.position.z = self.isAlarmPreview ? -0.04 : ClockFlybyPath.backdropDepth
        anchor.addChild(backdrop)

        applyLighting()
        loadTask = Task { @MainActor [weak self] in
            do {
                let environment = try await ClockLightingEnvironment.load()
                let content = try NumeralClockScene()
                try Task.checkCancellation()
                guard let self else { return }
                self.content = content
                realityRenderer?.lighting.resource = environment
                placement.addChild(content.root)
                updateTime()
                applyMaterials()
                setNeedsLayout()
            } catch is CancellationError {
                // Dismantling a view cancels any pending load.
            } catch {
                guard !Task.isCancelled else { return }
                self?.showLoadError(error)
            }
        }
    }

    private func showLoadError(_ error: Error) {
        // A failed initial load must still reveal its error while the clock is hidden.
        alpha = 1
        entranceAngles = .zero
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
    required init(coder: NSCoder) { fatalError("Use init(theme:)") }

    func applyTheme(_ theme: AppTheme) {
        guard self.theme != theme else { return }
        if self.theme.clockFlyby != theme.clockFlyby {
            flybys?.stop()
            flybys?.root.removeFromParent()
            flybys = nil
        }
        self.theme = theme
        flybys?.apply(appearance: theme.clock)
        applyLighting()
        applyMaterials()
        updateFlybys()
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
        realityRenderer?.lighting.intensityExponent = appearance.ambientIntensityExponent + Float(settings.fill)
        let background = UIColor(theme.palette.background)
        realityRenderer?.cameraSettings.colorBackground = .color(background.cgColor)
        backdrop.model?.materials = [appearance.backdropMaterial(color: background)]
        applyInteractionLighting()
        applyWeekdayLighting()
    }

    private func applyWeekdayLighting(verticalDirection: Float = 1) {
        guard !isAlarmPreview, !weekdayFrame.isEmpty, bounds.height > 0,
              cameraRestOffset.z > 0, let content,
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
        // The home label shines upward; widget exports place it above the row.
        let target = source + SIMD3<Float>(sin(direction), cos(direction) * verticalDirection, -1.5)
        weekdayLight.look(at: camera.convert(position: target, to: nil),
                          from: camera.convert(position: source, to: nil), relativeTo: nil)
    }

#if DEBUG
    /// Captures the final widget row, with the weekday shining down onto the hours.
    func prepareWidgetArtwork(time: String, visibleSlot: Int?) throws -> CGRect {
        guard let content, let realityRenderer, isReady else { throw CocoaError(.coderInvalidValue) }
        for digit in content.root.children { digit.isEnabled = true }
        content.show(time: "88:88")
        content.arrangeWidgetRow()
        layoutSubviews()
        let clockBounds = content.root.visualBounds(relativeTo: nil)
        let focalLength = Float(bounds.height) / (2 * tan(Float(6 * Double.pi / 180)))
        let scale = focalLength / (cameraRestOffset.z - clockBounds.max.z)
        let center = CGPoint(x: bounds.midX + CGFloat(clockBounds.center.x * scale),
                             y: bounds.midY - CGFloat(clockBounds.center.y * scale))
        let reference = ClockWidgetComposition.numerals
        let side = max(CGFloat(clockBounds.extents.x * scale) / reference.width,
                       CGFloat(clockBounds.extents.y * scale) / reference.height)
            * ClockWidgetComposition.side * 1.04
        let crop = CGRect(x: center.x - reference.midX / ClockWidgetComposition.side * side,
                          y: center.y - reference.midY / ClockWidgetComposition.side * side,
                          width: side, height: side)
        let label = ClockWidgetComposition.weekdayLight
        let labelScale = side / ClockWidgetComposition.side
        weekdayFrame = CGRect(x: crop.minX + label.minX * labelScale,
                              y: crop.minY + label.minY * labelScale,
                              width: label.width * labelScale, height: label.height * labelScale)
        applyWeekdayLighting(verticalDirection: -1)
        content.show(time: time)
        content.arrangeWidgetRow()
        for (index, digit) in content.root.children.enumerated() {
            digit.isEnabled = visibleSlot == nil || index == visibleSlot
        }
        backdrop.isEnabled = false
        realityRenderer.cameraSettings.colorBackground = .color(CGColor(gray: 0, alpha: 0))
        return crop
    }
#endif

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
                requestFrame()
                onContentChanged?()
                updateFlybys()
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
        let aspect = Float(bounds.width / bounds.height)
        // The preview's lit backdrop fills the entire modal, eliminating color seams.
        let visibleHeight: Float
        if previewNumeral != nil {
            visibleHeight = max(6.2, 3 / aspect)
        } else if isAlarmPreview {
            visibleHeight = max(Float(bounds.height / max(previewHeight, 1)) * 10.7, 4.4 / aspect)
        } else {
            visibleHeight = max(13.8, 4.4 / aspect)
        }
        let distance = visibleHeight / (2 * tan(Float(6 * Double.pi / 180))) + 0.6565
        let topInset = max(safeAreaInsets.top, contentSafeAreaInsets.top)
        let bottomInset = max(safeAreaInsets.bottom, contentSafeAreaInsets.bottom)
        let usableHeight = bounds.height - topInset - bottomInset
        let centerFromTop: CGFloat
        if previewNumeral != nil {
            centerFromTop = bounds.height * 0.5
        } else if isAlarmPreview {
            centerFromTop = topInset + previewTopInset + previewHeight * 0.50
        } else {
            centerFromTop = topInset + usableHeight * clockVerticalCenter
        }
        let centerY = visibleHeight * Float(0.5 - centerFromTop / bounds.height)
        placement.position = [0, centerY, 0]
        cameraRestOffset = [0, -centerY, distance]
        applyViewingAngle()
        updateWeekdayAnchor()
        updatePeriodAnchor()
        applyWeekdayLighting()
        updateFlybys()
    }

    private func updateFlybys() {
        if allowsAmbientAnimation, window != nil, isReady,
           !isAlarmPreview, theme.clock.surface == .grass {
            grassBreeze.onFrame = { [weak self] deltaTime in
                guard let self else { return }
                content?.advanceBreeze(by: deltaTime)
                requestFrame()
            }
            grassBreeze.start()
        } else {
            grassBreeze.stop()
        }
        guard allowsAmbientAnimation, window != nil, isReady,
              !isAlarmPreview, theme.clockFlyby != .none,
              bounds.width > 0, bounds.height > 0, cameraRestOffset.z > 1 else {
            flybys?.stop()
            return
        }
        if flybys == nil {
            do {
                let visitor = try ClockFlybyController(kind: theme.clockFlyby, appearance: theme.clock,
                                                      audioService: audioService)
                visitor.onFrame = { [weak self] in self?.requestFrame() }
                camera.addChild(visitor.root)
                flybys = visitor
            } catch {
                // A decorative asset failure must leave the clock usable.
                Logger(subsystem: "dev.ambitionsoftware.clock-app", category: "ClockFlyby")
                    .error("Could not create clock visitor: \(error.localizedDescription)")
                return
            }
        }
        let height = 2 * cameraRestOffset.z * tan(Float(6 * Double.pi / 180))
        flybys?.setViewport([height * Float(bounds.width / bounds.height), height],
                           cameraDistance: cameraRestOffset.z)
        flybys?.start()
    }

    private func updateWeekdayAnchor() {
        guard !isAlarmPreview, bounds.height > 0, cameraRestOffset.z > 0,
              let content,
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

    private func updatePeriodAnchor() {
        guard previewNumeral == nil, bounds.height > 0, cameraRestOffset.z > 0,
              let content, let hourDigit = content.lastHourDigit else { return }
        let hourBounds = hourDigit.visualBounds(relativeTo: nil)
        let clockBounds = content.root.visualBounds(relativeTo: nil)
        let focalLength = Float(bounds.height) / (2 * tan(Float(6 * Double.pi / 180)))
        let scale = focalLength / (cameraRestOffset.z - clockBounds.max.z)
        // Match the weekday's resting projection so the flat label stays still while orbiting.
        let anchor = CGPoint(
            x: bounds.midX + CGFloat(clockBounds.max.x * scale),
            y: bounds.midY - CGFloat(hourBounds.min.y * scale)
        )
        guard anchor != periodAnchor else { return }
        periodAnchor = anchor
        onPeriodAnchorChange?(anchor)
    }

    private func applyViewingAngle() {
        let orbit = orbitInteraction?.motion.orientation ?? simd_quatf(angle: 0, axis: [0, 1, 0])
        let entrance = simd_quatf(angle: entranceAngles.x, axis: [0, 1, 0])
            * simd_quatf(angle: entranceAngles.y, axis: [1, 0, 0])
        let orientation = orbit * entrance
        camera.orientation = orientation
        camera.position = placement.position + orientation.act(cameraRestOffset)
        applyInteractionLighting()
        applyWeekdayLighting()
        requestFrame()
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
        updateFlybys()
    }

    func show(display: ClockTimeDisplay) {
        guard self.display != display else { return }
        let previousDigits = self.display?.digits
        self.display = display
        accessibilityLabel = isAlarmPreview ? "Alarm time, \(display.text)" : "Time, \(display.text)"
        // A locale or period change can update accessibility without submitting an identical scene.
        if previousDigits != display.digits { updateTime() }
    }

    private func updateTime() {
        if let previewNumeral {
            content?.show(numeral: previewNumeral)
        } else if let display {
            content?.show(time: display.digits)
        }
        updateWeekdayAnchor()
        updatePeriodAnchor()
        applyWeekdayLighting()
        requestFrame()
    }

    func settleInteraction() {
        orbitInteraction?.reset()
    }

    func stop() {
        grassBreeze.stop()
        flybys?.stop()
        flybys = nil
        loadTask?.cancel()
        loadTask = nil
        materialTask?.cancel()
        materialTask = nil
        materialRevision += 1
        orbitInteraction?.reset()
        isRenderingEnabled = false
        realityRenderer?.entities.removeAll()
        content = nil
    }
}
