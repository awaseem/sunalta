import RealityKit
import SwiftUI
import UIKit

struct BlenderClockView: UIViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    let date: Date
    var isScrolling = false
    var isVisible = true
    var contentSafeAreaInsets: UIEdgeInsets = .zero

    func makeUIView(context: Context) -> ClockPageView {
        ClockPageView(colorScheme: colorScheme)
    }

    func updateUIView(_ view: ClockPageView, context: Context) {
        view.update(date: date, colorScheme: colorScheme, insets: contentSafeAreaInsets,
                    isScrolling: isScrolling, isVisible: isVisible)
    }

    static func dismantleUIView(_ view: ClockPageView, coordinator: ()) {
        view.stop()
    }
}

struct AlarmClockPreview: UIViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    let time: String
    let days: Set<ClockWeekday>
    let previewHeight: CGFloat
    let contentSafeAreaInsets: UIEdgeInsets

    func makeUIView(context: Context) -> ClockRenderView {
        ClockRenderView(colorScheme: colorScheme, isAlarmPreview: true)
    }

    func updateUIView(_ view: ClockRenderView, context: Context) {
        view.contentSafeAreaInsets = contentSafeAreaInsets
        view.previewHeight = previewHeight
        view.applyAppearance(colorScheme)
        view.showAlarm(time: time, days: days)
    }
}

final class ClockRenderView: ARView {
    var onOrbitBegan: (() -> Void)?
    var onOrbitSettled: (() -> Void)?
    var previewHeight: CGFloat = 240 {
        didSet { if oldValue != previewHeight { setNeedsLayout() } }
    }
    private static var glyphCache: [String: [String: ModelEntity]] = [:]
    private var glyphBounds: [String: BoundingBox] = [:]
    private var timeSlots: [ModelEntity] = []
    private let isAlarmPreview: Bool
    private var displayedRepeatDays: Set<ClockWeekday>?
    var contentSafeAreaInsets: UIEdgeInsets = .zero {
        didSet {
            if oldValue != contentSafeAreaInsets { setNeedsLayout() }
        }
    }
    private let clock = Entity()
    private let backdrop = ModelEntity()
    private let calendarDetails = Entity()
    private var weekdayLabel: ModelEntity?
    private var weekdaySymbol: ModelEntity?
    private var displayedWeekday: ClockWeekday?
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
    private var glyphs: [String: ModelEntity] = [:]
    private var displayedTime: String?

    init(colorScheme: ColorScheme, isAlarmPreview: Bool = false) {
        self.isAlarmPreview = isAlarmPreview
        super.init(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        renderOptions = [.disableMotionBlur, .disableDepthOfField, .disableCameraGrain]
        isAccessibilityElement = true
        accessibilityTraits = .staticText

        let anchor = AnchorEntity(world: .zero)
        scene.addAnchor(anchor)
        anchor.addChild(placement)
        placement.addChild(calendarDetails)
        placement.addChild(clock)
        clock.scale.y = 1.25
        camera.camera.fieldOfViewInDegrees = 12
        let orbitGesture = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        orbitGesture.delegate = self
        addGestureRecognizer(orbitGesture)
        accessibilityHint = isAlarmPreview
            ? "Drag to change the viewing angle. Release to return to the front view."
            : "Drag horizontally to change the viewing angle. Swipe up to see alarms."
        anchor.addChild(camera)

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
            glyphs = try Self.loadGlyphs(resource: "Numerals", keys: "0123456789:".map(String.init))
            let weekdayKeys = ClockWeekday.allCases.flatMap { [$0.abbreviation, $0.symbol] }
            let weekdays = try Self.loadGlyphs(resource: "Weekdays", keys: weekdayKeys)
            glyphs.merge(weekdays) { _, new in new }
            glyphBounds = glyphs.mapValues { $0.visualBounds(relativeTo: $0) }
        } catch {
            let message = UILabel()
            message.text = "Unable to load Blender clock assets"
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

        let material = appearance.numeralMaterial
        for glyph in glyphs.values {
            glyph.model?.materials = [material]
        }
        for container in [clock, calendarDetails] {
            for case let glyph as ModelEntity in container.children {
                glyph.model?.materials = [material]
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }
        let aspect = Float(bounds.width / bounds.height)
        // The preview's lit backdrop fills the entire modal, eliminating color seams.
        let visibleHeight = isAlarmPreview
            ? max(Float(bounds.height / max(previewHeight, 1)) * 5.8, 7.0 / aspect)
            : max(12.3, 7.0 / aspect)
        let distance = visibleHeight / (2 * tan(Float(6 * Double.pi / 180))) + 0.6565
        let topInset = max(safeAreaInsets.top, contentSafeAreaInsets.top)
        let bottomInset = max(safeAreaInsets.bottom, contentSafeAreaInsets.bottom)
        let usableHeight = bounds.height - topInset - bottomInset
        let centerFromTop = isAlarmPreview
            ? topInset + 44 + previewHeight * 0.40
            : topInset + usableHeight / 6 + 36
        let centerY = visibleHeight * Float(0.5 - centerFromTop / bounds.height)
        placement.position = [0, centerY, 0]
        cameraRestOffset = [0, -centerY, distance]
        layoutCalendarDetails()
        applyViewingAngle()
    }

    private func layoutCalendarDetails() {
        guard bounds.height > 0, cameraRestOffset.z > 0, !clock.children.isEmpty else { return }
        if isAlarmPreview {
            layoutRepeatDays()
            return
        }
        let timeBounds = clock.visualBounds(relativeTo: placement)
        let unitsPerPoint = (cameraRestOffset.z - timeBounds.max.z) * 2
            * tan(Float(6 * Double.pi / 180)) / Float(bounds.height)
        let gap = 12 * unitsPerPoint
        if let label = weekdayLabel {
            let meshBounds = label.visualBounds(relativeTo: label)
            let scale = 28 * unitsPerPoint / meshBounds.extents.y
            label.scale = [scale / 1.25, scale, scale / 1.25]
            let depthRatio = (cameraRestOffset.z - 0.025 - meshBounds.max.z * label.scale.z)
                / (cameraRestOffset.z - timeBounds.max.z)
            label.position = [
                timeBounds.min.x * depthRatio - meshBounds.min.x * label.scale.x,
                (placement.position.y + timeBounds.min.y - gap) * depthRatio
                    - placement.position.y - meshBounds.max.y * scale,
                0.025
            ]
        }
        if let symbol = weekdaySymbol {
            let meshBounds = symbol.visualBounds(relativeTo: symbol)
            let scale = 26 * unitsPerPoint / max(meshBounds.extents.x, meshBounds.extents.y)
            symbol.scale = SIMD3(repeating: scale)
            let depthRatio = (cameraRestOffset.z - 0.025 - meshBounds.max.z * scale)
                / (cameraRestOffset.z - timeBounds.max.z)
            symbol.position = [
                timeBounds.max.x * depthRatio - meshBounds.max.x * scale,
                (placement.position.y + timeBounds.max.y + gap) * depthRatio
                    - placement.position.y - meshBounds.min.y * scale,
                0.025
            ]
        }
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
        let time = String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
        let weekday = ClockWeekday(date: date)
        accessibilityLabel = "\(weekday.name), time, \(time)"
        if displayedWeekday != weekday,
           let label = glyphs[weekday.abbreviation], let symbol = glyphs[weekday.symbol] {
            displayedWeekday = weekday
            calendarDetails.children.removeAll()
            let newLabel = label.clone(recursive: true)
            let newSymbol = symbol.clone(recursive: true)
            calendarDetails.addChild(newLabel)
            calendarDetails.addChild(newSymbol)
            weekdayLabel = newLabel
            weekdaySymbol = newSymbol
            layoutCalendarDetails()
        }
        show(time: time)
        layoutCalendarDetails()
    }

    func showAlarm(time: String, days: Set<ClockWeekday>) {
        guard displayedTime != time || displayedRepeatDays != days else { return }
        show(time: time)
        if displayedRepeatDays != days {
            displayedRepeatDays = days
            calendarDetails.children.removeAll()
            for day in AlarmRepeatSummary.orderedDays where days.contains(day) {
                if let glyph = glyphs[day.abbreviation] {
                    calendarDetails.addChild(glyph.clone(recursive: true))
                }
            }
        }
        layoutCalendarDetails()
        accessibilityLabel = "\(time), \(AlarmRepeatSummary.text(for: days))"
    }

    private func layoutRepeatDays() {
        let labels = calendarDetails.children.compactMap { $0 as? ModelEntity }
        guard !labels.isEmpty else { return }
        let timeBounds = clock.visualBounds(relativeTo: placement)
        let gap: Float = 0.18
        let widths = labels.map { label -> Float in
            label.scale = SIMD3(repeating: 1)
            let bounds = label.visualBounds(relativeTo: label)
            return bounds.extents.x * 0.60 / bounds.extents.y
        }
        let totalWidth = widths.reduce(0, +) + gap * Float(labels.count - 1)
        let fit = min(1, timeBounds.extents.x / totalWidth)
        var cursor = -totalWidth * fit / 2
        for (index, label) in labels.enumerated() {
            let bounds = label.visualBounds(relativeTo: label)
            let scale = 0.60 / bounds.extents.y * fit
            label.scale = SIMD3(repeating: scale)
            label.position = [cursor - bounds.min.x * scale,
                              timeBounds.min.y - 0.35 - bounds.max.y * scale, 0.025]
            cursor += (widths[index] + gap) * fit
        }
    }

    private func show(time: String) {
        guard time != displayedTime, !glyphs.isEmpty else { return }
        let previous = Array(displayedTime ?? "")
        displayedTime = time
        let characters = Array(time)
        // Keep the same five scene entities. Only changed slots receive a cached model.
        while timeSlots.count < characters.count {
            let slot = ModelEntity()
            clock.addChild(slot)
            timeSlots.append(slot)
        }
        var cursor: Float = 0
        for (index, character) in characters.enumerated() {
            let key = String(character)
            guard let prototype = glyphs[key], let bounds = glyphBounds[key] else { continue }
            let glyph = timeSlots[index]
            if index >= previous.count || previous[index] != character {
                glyph.model = prototype.model
            }
            let width: Float = isAlarmPreview && character != ":" ? 1.35 : bounds.extents.x
            glyph.position = [cursor + width / 2 - bounds.center.x,
                              character == ":" ? -bounds.center.y : 0, 0]
            cursor += width + 0.12
        }
        let width = cursor - 0.12
        for glyph in clock.children {
            glyph.position.x -= width / 2
        }
    }

    private static func loadGlyphs(resource: String, keys: [String]) throws -> [String: ModelEntity] {
        if let cached = glyphCache[resource] {
            return cached.mapValues { $0.clone(recursive: true) }
        }
        struct MeshData: Decodable {
            let positions: [[Float]]
            let normals: [[Float]]
            let indices: [UInt32]
        }
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try JSONDecoder().decode([String: MeshData].self, from: Data(contentsOf: url))
        var result: [String: ModelEntity] = [:]
        for character in keys {
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
        glyphCache[resource] = result
        return result.mapValues { $0.clone(recursive: true) }
    }
}
