#if DEBUG
import CoreGraphics
import OSLog
import RealityKit
import SwiftUI
import UIKit

/// Reproducible artwork export using the clock's authored mesh, materials and lighting.
/// Launch a Debug build with --export-theme-icons; output goes to Documents/ThemeIcons.
@MainActor
enum ThemeIconExporter {
    static func exportIfRequested() async {
        guard ProcessInfo.processInfo.arguments.contains("--export-theme-icons") else { return }
        do {
            let folder = URL.documentsDirectory.appending(path: "ThemeIcons", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let completion = folder.appending(path: "complete.txt")
            if FileManager.default.fileExists(atPath: completion.path()) {
                try FileManager.default.removeItem(at: completion)
            }
            for theme in AppTheme.available {
                var dark = theme
                if theme.id == AppTheme.white.id {
                    dark.palette.background = Color(red: 0.12, green: 0.105, blue: 0.11)
                    // Subdued neutral light and a matte finish keep the red beam saturated.
                    dark.clock.numeralColor = Color(white: 0.55)
                    dark.clock.roughness = 0.32
                    dark.clock.clearcoat = 0.15
                    dark.clock.clearcoatRoughness = 0.3
                    dark.clock.lighting.strength = 450
                    dark.clock.lighting.fill = -2.4
                    // Reduce the accent intensity to preserve detail on the graphite material.
                    dark.weekday.glow.brightness *= 0.108375
                } else if theme.id == AppTheme.grass.id {
                    dark.palette.background = Color(red: 0.055, green: 0.085, blue: 0.035)
                }
                var light = theme
                // Keep the original theme material in light mode; reserve colored light for dark icons.
                light.weekday.glow.brightness = 0
                try await render(theme: light, to: folder.appending(path: "\(theme.id).png"))
                try await render(theme: dark, to: folder.appending(path: "\(theme.id)-dark.png"))
                var tinted = theme
                tinted.palette.background = .black
                if theme.id == AppTheme.white.id {
                    // Keep White's neutral tint artwork independent of Midnight's lantern lighting.
                    tinted.clock = ClockAppearance(
                        numeralColor: .white,
                        lighting: ClockLightingSettings(direction: 0.36, tilt: 50.24, strength: 2400, fill: 0.25)
                    )
                    // Preserve facet contrast when mapping the pale material to grayscale.
                    tinted.weekday.glow.brightness *= 0.1
                }
                try await render(theme: tinted, to: folder.appending(path: "\(theme.id)-tinted.png"), grayscale: true)
            }
            try Data("Finished".utf8).write(to: completion)
        } catch {
            Logger(subsystem: "dev.ambitionsoftware.sunalta", category: "IconExport")
                .error("Icon export failed: \(error)")
        }
    }

    private static func render(theme: AppTheme, to url: URL, grayscale: Bool = false) async throws {
        let width = 1024
        let height = 1024
        let renderer = try RealityRenderer()
        renderer.cameraSettings.antialiasing = .multisample4X
        renderer.cameraSettings.colorBackground = .color(
            UIColor(theme.palette.background).cgColor
        )
        renderer.lighting.resource = try await ClockLightingEnvironment.load()
        renderer.lighting.intensityExponent = theme.clock.ambientIntensityExponent
            + Float(theme.clock.lighting.fill)

        let content = try NumeralClockScene()
        content.show(numeral: "1")
        try await content.apply(theme: theme)
        renderer.entities.append(content.root)

        let light = DirectionalLight()
        light.light.color = UIColor(theme.clock.lightColor)
        light.light.intensity = Float(theme.clock.lighting.strength)
        light.look(at: .zero, from: theme.clock.lighting.lightPosition, relativeTo: nil)
        renderer.entities.append(light)

        let camera = Entity()
        var projection = PerspectiveCameraComponent()
        projection.fieldOfViewInDegrees = 12
        camera.components.set(projection)
        // The icon's cap sits near the top edge and its stem extends below the frame.
        let bounds = content.firstDigit?.model?.mesh.bounds
        let glyphHeight = (bounds?.extents.y ?? 3.712) * 1.15
        let visibleHeight = glyphHeight * 0.50
        let centerY = glyphHeight / 2 - visibleHeight * 0.35
        camera.position = [0, centerY, visibleHeight / (2 * tan(.pi / 30)) + 0.6565]
        renderer.entities.append(camera)
        renderer.activeCamera = camera

        if theme.weekday.glow.brightness > 0 {
            // Place the theme's accent light below the crop, shining up onto the numeral's curved cap.
            let glow = theme.weekday.glow
            let accentLight = SpotLight()
            // Give White's red accent more presence; keep grayscale detail and Midnight's softer beam.
            let intensityScale = theme.id == AppTheme.white.id && !grayscale ? 750.0 : 375.0
            accentLight.light = SpotLightComponent(
                color: UIColor(Color(glow.color)), intensity: Float(glow.brightness * intensityScale),
                innerAngleInDegrees: Float(glow.spread * 0.35),
                outerAngleInDegrees: Float(glow.spread), attenuationRadius: Float(glow.reach)
            )
            let source = SIMD3<Float>(-visibleHeight * 0.35, centerY - visibleHeight * 0.65,
                                      (bounds?.max.z ?? 0.6565) + 2)
            let direction = Float(glow.direction * .pi / 180)
            let target = source + SIMD3<Float>(sin(direction), cos(direction), -1.5)
            accentLight.look(at: target, from: source, relativeTo: nil)
            renderer.entities.append(accentLight)
        }

        let image = try await ClockArtworkRenderer.renderImage(renderer: renderer, width: width, height: height,
                                          transparent: false)
        let finalImage: CGImage
        if grayscale {
            guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
                                          bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
                throw CocoaError(.fileWriteUnknown)
            }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            guard let grayImage = context.makeImage() else { throw CocoaError(.fileWriteUnknown) }
            finalImage = grayImage
        } else {
            finalImage = image
        }
        try ClockArtworkRenderer.write(finalImage, to: url)
    }
}
#endif
