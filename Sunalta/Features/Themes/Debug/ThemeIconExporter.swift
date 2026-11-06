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
                try await render(theme: theme, to: folder.appending(path: "\(theme.id).png"))
                var dark = theme
                if theme.id == AppTheme.white.id {
                    dark.palette.background = .black
                    // Graphite keeps the curved face legible and distinct from Midnight's white numeral.
                    dark.clock.numeralColor = Color(white: 0.28)
                    dark.clock.ambientIntensityExponent += 1
                } else if theme.id == AppTheme.grass.id {
                    dark.palette.background = Color(red: 0.055, green: 0.085, blue: 0.035)
                }
                try await render(theme: dark, to: folder.appending(path: "\(theme.id)-dark.png"))
                var tinted = theme
                tinted.palette.background = .black
                if theme.clock.surface == .plastic { tinted.clock = AppTheme.midnight.clock }
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
