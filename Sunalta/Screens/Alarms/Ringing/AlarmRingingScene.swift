import OSLog
import RealityKit
import SwiftUI

/// A single render surface keeps the bell animating beside the static 3D time row.
@MainActor
final class AlarmRingingScene {
    let root = Entity()
    let bell: AlarmBellScene
    private let numerals: NumeralClockScene
    private let timePlacement = Entity()
    private let bellPlacement = Entity()
    private let camera = Entity()
    private let studio = Entity()
    private let keyLight = DirectionalLight()
    private var display: ClockTimeDisplay?
    private var appliedTheme: AppTheme?
    private var viewport = CGSize.zero
    private var timeFrame = CGRect.zero
    private var bellFrame = CGRect.zero
    private var flybys: AlarmFlybyController?
    private var burstTiming = AlarmBurstTiming(swingDuration: AlarmBellScene.swingDuration)
    private var ambienceActive = false

    init() async throws {
        bell = try await AlarmBellScene()
        numerals = try NumeralClockScene()
        let environment = try await ClockLightingEnvironment.load()
        try Task.checkCancellation()
        studio.components.set(ImageBasedLightComponent(source: .single(environment)))
        numerals.root.components.set(ImageBasedLightReceiverComponent(imageBasedLight: studio))
        timePlacement.addChild(numerals.root)
        timePlacement.addChild(studio)
        timePlacement.addChild(keyLight)
        bellPlacement.addChild(bell.root)
        camera.position.z = 1_000
        root.addChild(timePlacement)
        root.addChild(bellPlacement)
        root.addChild(camera)
    }

    func show(display: ClockTimeDisplay) {
        guard self.display?.digits != display.digits else { return }
        self.display = display
        numerals.show(time: display.digits)
        numerals.arrangeRow()
        updateLayout()
    }

    func apply(theme: AppTheme) async throws {
        guard appliedTheme != theme else { return }
        try bell.apply(theme: theme)
        try await numerals.apply(theme: theme)
        try Task.checkCancellation()
        if appliedTheme?.clockFlyby != theme.clockFlyby {
            flybys?.stop()
            flybys?.root.removeFromParent()
            flybys = nil
        }
        if theme.clockFlyby != .none, flybys == nil {
            do {
                let flybys = try AlarmFlybyController(kind: theme.clockFlyby, appearance: theme.clock)
                flybys.root.components.set(ImageBasedLightReceiverComponent(imageBasedLight: studio))
                root.addChild(flybys.root)
                self.flybys = flybys
            } catch {
                Logger(subsystem: "dev.ambitionsoftware.sunalta", category: "AlarmFlyby")
                    .error("Could not create alarm visitors: \(error.localizedDescription)")
            }
        }
        flybys?.apply(appearance: theme.clock)
        appliedTheme = theme
        numerals.arrangeRow()
        studio.components[ImageBasedLightComponent.self]?.intensityExponent =
            theme.clock.ambientIntensityExponent + Float(theme.clock.lighting.fill)
        keyLight.light.color = .init(theme.clock.lightColor)
        keyLight.light.intensity = Float(theme.clock.lighting.strength)
        keyLight.look(at: .zero, from: theme.clock.lighting.lightPosition, relativeTo: timePlacement)
        updateLayout()
    }

    func setLayout(viewport: CGSize, timeFrame: CGRect, bellFrame: CGRect) {
        self.viewport = viewport
        self.timeFrame = timeFrame
        self.bellFrame = bellFrame
        updateLayout()
    }

    func setAmbienceActive(_ active: Bool) {
        ambienceActive = active
        if !active { flybys?.stop() }
    }

    func advance(by deltaTime: TimeInterval) {
        bell.advanceReveal(by: deltaTime)
        guard ambienceActive else { return }
        flybys?.advance(by: deltaTime)
        if burstTiming.advance(by: deltaTime, bellTime: bell.swingTime) { flybys?.burst() }
    }

    private func updateLayout() {
        guard viewport.width > 0, viewport.height > 0,
              timeFrame.width > 0, timeFrame.height > 0,
              bellFrame.width > 0, bellFrame.height > 0 else { return }
        var projection = OrthographicCameraComponent()
        projection.scaleDirection = .vertical
        // Orthographic scale is the half-height of the visible world.
        projection.scale = Float(viewport.height / 2)
        projection.near = 0.1
        projection.far = 2_000
        camera.components.set(projection)
        flybys?.setViewport(viewport)

        let bounds = numerals.root.visualBounds(relativeTo: timePlacement)
        let timeScale = min(Float(timeFrame.width) / max(bounds.extents.x * 1.15, 0.001),
                            Float(timeFrame.height) / max(bounds.extents.y * 1.2, 0.001))
        timePlacement.scale = SIMD3(repeating: timeScale)
        timePlacement.position = position(for: timeFrame) - bounds.center * timeScale

        let visibleBellHeight = max(3.8, 3.4 / Float(bellFrame.width / bellFrame.height))
        bellPlacement.scale = SIMD3(repeating: Float(bellFrame.height) / visibleBellHeight)
        bellPlacement.position = position(for: bellFrame)
    }

    private func position(for frame: CGRect) -> SIMD3<Float> {
        [Float(frame.midX - viewport.width / 2), Float(viewport.height / 2 - frame.midY), 0]
    }
}
