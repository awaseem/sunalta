import Foundation
import RealityKit

/// Native buffers imported from the Three.js GLBs, shared by all clock views.
@MainActor
enum ClockGlyphAssets {
    private static var cache: [String: ModelEntity]?

    static func load() throws -> [String: ModelEntity] {
        if let cache { return cache.mapValues { $0.clone(recursive: true) } }
        guard let url = Bundle.main.url(forResource: "SculptedNumerals", withExtension: "clockmesh") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        guard data.prefix(8) == Data("CLKMESH1".utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let result = try data.withUnsafeBytes { bytes -> [String: ModelEntity] in
            var reader = Reader(bytes: bytes, offset: 8)
            guard try reader.uint32() == 11 else { throw CocoaError(.fileReadCorruptFile) }
            var glyphs: [String: ModelEntity] = [:]
            for _ in 0..<11 {
                let code = try reader.uint32()
                guard let scalar = UnicodeScalar(code), "0123456789:".unicodeScalars.contains(scalar) else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                let key = String(scalar)
                let vertexCount = Int(try reader.uint32())
                let indexCount = Int(try reader.uint32())
                guard glyphs[key] == nil, vertexCount > 0, vertexCount <= 1_000_000,
                      indexCount > 0, indexCount <= 6_000_000, indexCount.isMultiple(of: 3) else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                var descriptor = MeshDescriptor(name: "Sculpted digit \(key)")
                descriptor.positions = MeshBuffers.Positions(try reader.vectors3(count: vertexCount))
                descriptor.normals = MeshBuffers.Normals(try reader.vectors3(count: vertexCount))
                descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(try reader.vectors2(count: vertexCount))
                try reader.require(indexCount * 4)
                let indices = try (0..<indexCount).map { _ -> UInt32 in
                    let index = try reader.uint32()
                    guard index < vertexCount else { throw CocoaError(.fileReadCorruptFile) }
                    return index
                }
                descriptor.primitives = .triangles(indices)
                glyphs[key] = ModelEntity(mesh: try MeshResource.generate(from: [descriptor]), materials: [])
            }
            guard reader.offset == bytes.count else { throw CocoaError(.fileReadCorruptFile) }
            return glyphs
        }
        cache = result
        return result.mapValues { $0.clone(recursive: true) }
    }

    private struct Reader {
        let bytes: UnsafeRawBufferPointer
        var offset: Int

        func require(_ count: Int) throws {
            guard count <= bytes.count - offset else { throw CocoaError(.fileReadCorruptFile) }
        }

        mutating func uint32() throws -> UInt32 {
            try require(4)
            defer { offset += 4 }
            return UInt32(littleEndian: bytes.loadUnaligned(fromByteOffset: offset, as: UInt32.self))
        }

        mutating func float() throws -> Float {
            let value = Float(bitPattern: try uint32())
            guard value.isFinite else { throw CocoaError(.fileReadCorruptFile) }
            return value
        }

        mutating func vectors3(count: Int) throws -> [SIMD3<Float>] {
            try require(count * 12)
            return try (0..<count).map { _ in SIMD3(try float(), try float(), try float()) }
        }

        mutating func vectors2(count: Int) throws -> [SIMD2<Float>] {
            try require(count * 8)
            return try (0..<count).map { _ in SIMD2(try float(), try float()) }
        }
    }
}
