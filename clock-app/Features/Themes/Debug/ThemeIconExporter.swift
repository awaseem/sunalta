#if DEBUG
import ImageIO
import Metal
import OSLog
import RealityKit
import SwiftUI
import UIKit
import UniformTypeIdentifiers

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
                    dark.palette.background = Color(white: 0.32)
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
            Logger(subsystem: "dev.ambitionsoftware.clock-app", category: "IconExport")
                .error("Icon export failed: \(error)")
        }
    }

    private static func render(theme: AppTheme, to url: URL, grayscale: Bool = false) async throws {
        let size = 1024
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let event = device.makeEvent() else { throw CocoaError(.featureUnsupported) }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb, width: size, height: size, mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .shared
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw CocoaError(.featureUnsupported)
        }
        let renderer = try RealityRenderer()
        renderer.cameraSettings.antialiasing = .multisample4X
        renderer.cameraSettings.colorBackground = .color(UIColor(theme.palette.background).cgColor)
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
        // The cap sits near the top edge and the stem continues beyond the bottom.
        // Keep this framing identical across materials, including the grass blades.
        let bounds = content.firstDigit?.model?.mesh.bounds
        let glyphHeight = (bounds?.extents.y ?? 3.712) * 1.15
        let visibleHeight = glyphHeight * 0.50
        let centerY = glyphHeight / 2 - visibleHeight * 0.35
        camera.position = [0, centerY, visibleHeight / (2 * tan(.pi / 30)) + 0.6565]
        renderer.entities.append(camera)
        renderer.activeCamera = camera

        let output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: texture))
        // Allow material pipelines and exposure to settle before saving the still.
        for frame in 1...4 {
            try renderer.updateAndRender(deltaTime: 1 / 60, cameraOutput: output,
                                         actionsAfterRender: [.signal(event, value: UInt64(frame))])
            guard let command = queue.makeCommandBuffer() else { throw CocoaError(.featureUnsupported) }
            command.encodeWaitForEvent(event, value: UInt64(frame))
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                command.addCompletedHandler { buffer in
                    if let error = buffer.error { continuation.resume(throwing: error) }
                    else { continuation.resume() }
                }
                command.commit()
            }
        }
        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        texture.getBytes(&pixels, bytesPerRow: size * 4,
                         from: MTLRegionMake2D(0, 0, size, size), mipmapLevel: 0)
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let image = CGImage(width: size, height: size, bitsPerComponent: 8, bitsPerPixel: 32,
                                  bytesPerRow: size * 4, space: space,
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)
                                    .union(.byteOrder32Little),
                                  provider: provider, decode: nil, shouldInterpolate: true,
                                  intent: .defaultIntent),
              let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString,
                                                               1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        let finalImage: CGImage
        if grayscale {
            guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                                          bytesPerRow: size, space: CGColorSpaceCreateDeviceGray(),
                                          bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
                throw CocoaError(.fileWriteUnknown)
            }
            context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
            guard let grayImage = context.makeImage() else { throw CocoaError(.fileWriteUnknown) }
            finalImage = grayImage
        } else {
            finalImage = image
        }
        CGImageDestinationAddImage(destination, finalImage, nil)
        guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
    }
}
#endif
