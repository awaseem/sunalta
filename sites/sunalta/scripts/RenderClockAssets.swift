import AppKit
import CoreText
import Foundation
import ImageIO
import RealityKit

/// Website artwork, using the app's CLKMESH2 meshes and RealityKit material recipe.
/// Compile alongside ClockMeshReader.swift and ClockArtworkRenderer.swift.
@main
struct RenderClockAssets {
    @MainActor
    static func main() async throws {
        guard CommandLine.arguments.count == 3 || (CommandLine.arguments.count == 4 && CommandLine.arguments[3] == "--social-only") else {
            throw CocoaError(.fileReadInvalidFileName)
        }
        let repository = URL(filePath: CommandLine.arguments[1], directoryHint: .isDirectory)
        let output = URL(filePath: CommandLine.arguments[2], directoryHint: .isDirectory)
        if CommandLine.arguments.last == "--social-only" {
            let posterURL = output.appending(path: "poster.png")
            guard let source = CGImageSourceCreateWithURL(posterURL as CFURL, nil),
                  let poster = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            try makeSocialImage(clock: poster, at: repository.appending(path: "sites/sunalta/public/social.png"))
            print("Updated social artwork")
            return
        }
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let glyphs = try loadGlyphs(from: repository.appending(path: "Sunalta/Resources/SharpNumerals.clockmesh"))
        let bounds = glyphs.mapValues { $0.visualBounds(relativeTo: $0) }
        let columnWidth = bounds.values.map(\.extents.x).max() ?? 1.6
        let rowHeight = (bounds.values.map(\.extents.y).max() ?? 3.712) * 1.15
        let scale = min(1, 3.8 / (2 * columnWidth + 0.14))

        let renderer = try RealityRenderer()
        renderer.cameraSettings.antialiasing = .multisample4X
        renderer.cameraSettings.colorBackground = .color(NSColor.clear.cgColor)
        let environmentURL = repository.appending(path: "Sunalta/Resources/ClockStudio.skybox/ClockStudio.exr")
        guard let source = CGImageSourceCreateWithURL(environmentURL as CFURL, nil),
              let environment = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        renderer.lighting.resource = try await EnvironmentResource(equirectangular: environment)
        renderer.lighting.intensityExponent = -1

        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: NSColor(srgbRed: 0.035, green: 0.035, blue: 0.035, alpha: 1))
        material.metallic = .init(floatLiteral: 0)
        material.roughness = .init(floatLiteral: 0.16)
        material.clearcoat = .init(floatLiteral: 0.8)
        material.clearcoatRoughness = .init(floatLiteral: 0.08)

        let root = Entity()
        root.scale = SIMD3(repeating: scale)
        root.position.y = 1.1
        renderer.entities.append(root)
        let slots = (0..<4).map { _ in ModelEntity() }
        for slot in slots { root.addChild(slot) }

        func show(_ digits: String) throws {
            for (index, character) in digits.enumerated() {
                let key = String(character)
                guard let glyph = glyphs[key], let bound = bounds[key] else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                let slot = slots[index]
                slot.model = glyph.model
                slot.model?.materials = [material]
                slot.scale = [1, 1.15, 1]
                let x = (index.isMultiple(of: 2) ? -Float(1) : 1) * (columnWidth + 0.14) / 2
                let y = (index < 2 ? Float(1) : -1) * (rowHeight + 0.28) / 2
                slot.position = [x - bound.center.x, y - bound.center.y * 1.15, 0]
            }
        }
        try show("8888")

        let light = DirectionalLight()
        light.light.intensity = 2600
        let azimuth = Float(0.36364316940307617 * .pi / 180)
        let tilt = Float(50.24 * .pi / 180)
        light.look(at: .zero, from: SIMD3(cos(azimuth) * sin(tilt), sin(azimuth) * sin(tilt), cos(tilt)) * 10,
                   relativeTo: nil)
        renderer.entities.append(light)

        let width = 1200
        let height = 2400
        let visibleHeight: Float = 13.8
        let distance = visibleHeight / (2 * tan(Float.pi / 30)) + 0.6565
        let camera = Entity()
        var projection = PerspectiveCameraComponent()
        projection.fieldOfViewInDegrees = 12
        camera.components.set(projection)
        camera.position = [0, 0, distance]
        renderer.entities.append(camera)
        renderer.activeCamera = camera

        // Use the envelope of every digit: 4 and 7 extend beyond the sides of 8.
        var clockBounds = root.visualBounds(relativeTo: nil)
        for digit in 0...9 {
            try show(String(repeating: String(digit), count: 4))
            clockBounds.formUnion(root.visualBounds(relativeTo: nil))
        }
        try show("8888")
        let focalLength = Float(height) / (2 * tan(Float.pi / 30))
        let pixelsPerUnit = focalLength / (distance - clockBounds.max.z)
        let cropX = Float(width) / 2 + clockBounds.min.x * pixelsPerUnit - 4
        let cropY = Float(height) / 2 - clockBounds.max.y * pixelsPerUnit - 4
        let cropWidth = clockBounds.extents.x * pixelsPerUnit + 8
        let cropHeight = clockBounds.extents.y * pixelsPerUnit + 8
        let crop = CGRect(x: CGFloat(cropX), y: CGFloat(cropY),
                          width: CGFloat(cropWidth), height: CGFloat(cropHeight)).integral

        // WhiteTheme's red weekday spotlight shines upward from below the first column.
        let accent = SpotLight()
        accent.light = SpotLightComponent(
            color: NSColor(srgbRed: 1, green: 0.08, blue: 0.16, alpha: 1),
            intensity: 3012.121081352234 * 500,
            innerAngleInDegrees: 21, outerAngleInDegrees: 60, attenuationRadius: 5.5181816
        )
        let sourcePosition = SIMD3<Float>(clockBounds.min.x + 0.6, clockBounds.min.y - 0.45, clockBounds.max.z + 2)
        let direction = Float(20.36363124847412 * .pi / 180)
        accent.look(at: sourcePosition + SIMD3(sin(direction), cos(direction), -1.5),
                    from: sourcePosition, relativeTo: nil)
        renderer.entities.append(accent)

        for position in 0..<4 {
            for digit in 0...9 {
                try show(String(repeating: String(digit), count: 4))
                for (index, slot) in slots.enumerated() { slot.isEnabled = index == position }
                let image = try await ClockArtworkRenderer.renderImage(
                    renderer: renderer, width: width, height: height, transparent: true
                )
                guard let cropped = image.cropping(to: crop) else { throw CocoaError(.fileWriteUnknown) }
                try ClockArtworkRenderer.write(cropped, to: output.appending(path: "\(position)-\(digit).png"))
            }
            print("Exported clock position \(position + 1)/4")
        }
        for slot in slots { slot.isEnabled = true }
        try show("0941")
        let poster = try await ClockArtworkRenderer.renderImage(
            renderer: renderer, width: width, height: height, transparent: true
        )
        guard let cropped = poster.cropping(to: crop) else { throw CocoaError(.fileWriteUnknown) }
        try ClockArtworkRenderer.write(cropped, to: output.appending(path: "poster.png"))
        let publicDirectory = repository.appending(path: "sites/sunalta/public", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: publicDirectory, withIntermediateDirectories: true)
        try makeSocialImage(clock: cropped, at: publicDirectory.appending(path: "social.png"))
        let iconURL = repository.appending(path: "Sunalta/Assets.xcassets/AppIcon.appiconset/Any.png")
        guard let iconSource = CGImageSourceCreateWithURL(iconURL as CFURL, nil),
              let icon = CGImageSourceCreateImageAtIndex(iconSource, 0, nil) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        for (name, size) in [("favicon", 64), ("apple-touch-icon", 180)] {
            guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                                          bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                throw CocoaError(.fileWriteUnknown)
            }
            context.interpolationQuality = .high
            context.draw(icon, in: CGRect(x: 0, y: 0, width: size, height: size))
            guard let image = context.makeImage() else { throw CocoaError(.fileWriteUnknown) }
            try ClockArtworkRenderer.write(image, to: publicDirectory.appending(path: "\(name).png"))
        }
        print("Exported home clock artwork: \(Int(crop.width)) × \(Int(crop.height))")
    }

    @MainActor
    private static func makeSocialImage(clock: CGImage, at url: URL) throws {
        guard let context = CGContext(data: nil, width: 1200, height: 630, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw CocoaError(.fileWriteUnknown)
        }
        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 1200, height: 630))
        let clockHeight: CGFloat = 500
        let clockWidth = clockHeight * CGFloat(clock.width) / CGFloat(clock.height)
        context.draw(clock, in: CGRect(x: 170, y: 90, width: clockWidth, height: clockHeight))
        func text(_ value: String, at point: CGPoint, size: CGFloat, color: NSColor, weight: NSFont.Weight = .regular) {
            let string = NSAttributedString(string: value, attributes: [
                .font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color
            ])
            context.textPosition = point
            CTLineDraw(CTLineCreateWithAttributedString(string), context)
        }
        text("Mon", at: CGPoint(x: 172, y: 49), size: 34,
             color: NSColor(srgbRed: 1, green: 0.08, blue: 0.16, alpha: 1), weight: .medium)
        text("Sunalta", at: CGPoint(x: 535, y: 368), size: 48, color: .black, weight: .semibold)
        text("A simple, sculpted", at: CGPoint(x: 535, y: 308), size: 28, color: .darkGray)
        text("alarm clock.", at: CGPoint(x: 535, y: 269), size: 28, color: .darkGray)
        text("Get out of bed. Scan an NFC tag or QR code.", at: CGPoint(x: 535, y: 213), size: 19, color: .darkGray)
        text("Stop your alarm. Start your day on your feet.", at: CGPoint(x: 535, y: 180), size: 19, color: .darkGray)
        guard let image = context.makeImage() else { throw CocoaError(.fileWriteUnknown) }
        try ClockArtworkRenderer.write(image, to: url)
    }

    @MainActor
    private static func loadGlyphs(from url: URL) throws -> [String: ModelEntity] {
        let data = try Data(contentsOf: url)
        guard data.prefix(8) == Data("CLKMESH2".utf8) else { throw CocoaError(.fileReadCorruptFile) }
        return try data.withUnsafeBytes { bytes in
            var reader = ClockMeshReader(bytes: bytes, offset: 8)
            guard try reader.uint32() == 11 else { throw CocoaError(.fileReadCorruptFile) }
            var result: [String: ModelEntity] = [:]
            for _ in 0..<11 {
                let code = try reader.uint32()
                let vertices = Int(try reader.uint32())
                let indicesCount = Int(try reader.uint32())
                guard let scalar = UnicodeScalar(code), vertices > 0, vertices <= 1_000_000,
                      indicesCount > 0, indicesCount <= 6_000_000, indicesCount.isMultiple(of: 3) else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                var mesh = MeshDescriptor()
                mesh.positions = .init(try reader.vectors3(count: vertices))
                mesh.normals = .init(try reader.vectors3(count: vertices))
                let indices = try (0..<indicesCount).map { _ in
                    let index = try reader.uint32()
                    guard index < vertices else { throw CocoaError(.fileReadCorruptFile) }
                    return index
                }
                mesh.primitives = .triangles(indices)
                if scalar != ":" {
                    result[String(scalar)] = ModelEntity(mesh: try MeshResource.generate(from: [mesh]), materials: [])
                }
            }
            guard reader.offset == bytes.count, result.count == 10 else { throw CocoaError(.fileReadCorruptFile) }
            return result
        }
    }
}
