#if DEBUG
import CoreGraphics
import Foundation
import ImageIO
import Metal
import RealityKit
import UniformTypeIdentifiers

/// Shared offscreen capture for the app icon and widget artwork exporters.
@MainActor
enum ClockArtworkRenderer {
    static func renderImage(renderer: RealityRenderer, width: Int, height: Int,
                            transparent: Bool) async throws -> CGImage {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let event = device.makeEvent() else { throw CocoaError(.featureUnsupported) }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb, width: width, height: height, mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .shared
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw CocoaError(.featureUnsupported)
        }
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
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        texture.getBytes(&pixels, bytesPerRow: width * 4,
                         from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                                  bytesPerRow: width * 4, space: space,
                                  bitmapInfo: CGBitmapInfo(rawValue: transparent
                                    ? CGImageAlphaInfo.premultipliedFirst.rawValue : CGImageAlphaInfo.noneSkipFirst.rawValue)
                                    .union(.byteOrder32Little),
                                  provider: provider, decode: nil, shouldInterpolate: true,
                                  intent: .defaultIntent) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return image
    }

    static func write(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil
        ) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
    }
}
#endif
