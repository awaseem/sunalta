import Foundation
import RealityKit

/// Evaluated meshes from ThirdParty/Blender/ClockSharp/clock-sharp.blend.
/// Shared prototypes retain Blender's bevels and corner normals.
@MainActor
enum ClockGlyphAssets {
    private static var cache: [String: ModelEntity]?

    static func load() throws -> [String: ModelEntity] {
        if let cache { return cache.mapValues { $0.clone(recursive: true) } }
        guard let url = Bundle.main.url(forResource: "SharpNumerals", withExtension: "clockmesh") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        guard data.prefix(8) == Data("CLKMESH2".utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let result = try data.withUnsafeBytes { bytes -> [String: ModelEntity] in
            var reader = ClockMeshReader(bytes: bytes, offset: 8)
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
                var descriptor = MeshDescriptor(name: "Sharp Blender glyph \(key)")
                descriptor.positions = MeshBuffers.Positions(try reader.vectors3(count: vertexCount))
                descriptor.normals = MeshBuffers.Normals(try reader.vectors3(count: vertexCount))
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

}
