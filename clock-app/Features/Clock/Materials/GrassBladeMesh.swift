import Foundation
import RealityKit

@MainActor
enum GrassBladeMesh {
    private struct Triangle {
        let positions: [SIMD3<Float>]
        let normals: [SIMD3<Float>]
        let cumulativeArea: Float
    }

    private struct Random {
        var state: UInt64 = 0x4752415353
        mutating func next() -> Float {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return Float(state >> 40) / Float(1 << 24)
        }
    }

    static func generate(on source: MeshResource) throws -> MeshResource {
        var triangles: [Triangle] = []
        var area: Float = 0
        var minimum = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        var maximum = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        let contents = source.contents
        for instance in contents.instances {
            guard let model = contents.models.first(where: { $0.id == instance.model }) else { continue }
            let transform = instance.transform
            let normalTransform = simd_transpose(simd_inverse(transform))
            for part in model.parts {
                guard let indices = part.triangleIndices?.elements else { continue }
                let positions = part.positions.elements.map { point in
                    let result = transform * SIMD4(point, 1)
                    return SIMD3(result.x, result.y, result.z)
                }
                let normals = part.normals?.elements.map { normal in
                    let result = normalTransform * SIMD4(normal, 0)
                    return simd_normalize(SIMD3(result.x, result.y, result.z))
                }
                for point in positions {
                    minimum = simd_min(minimum, point)
                    maximum = simd_max(maximum, point)
                }
                for offset in stride(from: 0, to: indices.count - 2, by: 3) {
                    let vertices = (0..<3).map { Int(indices[offset + $0]) }
                    guard vertices.allSatisfy({ positions.indices.contains($0) }) else { continue }
                    let points = vertices.map { positions[$0] }
                    let cross = simd_cross(points[1] - points[0], points[2] - points[0])
                    let triangleArea = simd_length(cross) / 2
                    guard triangleArea > 0.000001 else { continue }
                    area += triangleArea
                    let faceNormal = simd_normalize(cross)
                    let directions = vertices.map { index in
                        normals.flatMap { $0.indices.contains(index) ? $0[index] : nil } ?? faceNormal
                    }
                    triangles.append(Triangle(positions: points, normals: directions, cumulativeArea: area))
                }
            }
        }
        guard area > 0 else { throw CocoaError(.fileReadCorruptFile) }
        let extent = maximum - minimum
        let size = max(extent.x, max(extent.y, extent.z))
        let bladeCount = 8_000
        var random = Random()
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var coordinates: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        positions.reserveCapacity(bladeCount * 5)
        normals.reserveCapacity(bladeCount * 5)
        coordinates.reserveCapacity(bladeCount * 5)
        indices.reserveCapacity(bladeCount * 9)

        for _ in 0..<bladeCount {
            // Area weighting avoids visible seams where the source mesh is more finely tessellated.
            let sample = random.next() * area
            var low = 0
            var high = triangles.count - 1
            while low < high {
                let middle = (low + high) / 2
                if triangles[middle].cumulativeArea < sample { low = middle + 1 } else { high = middle }
            }
            let triangle = triangles[low]
            let u = sqrt(random.next())
            let v = random.next()
            let weights = SIMD3(1 - u, u * (1 - v), u * v)
            let root = triangle.positions[0] * weights.x + triangle.positions[1] * weights.y
                + triangle.positions[2] * weights.z
            let normal = simd_normalize(triangle.normals[0] * weights.x
                + triangle.normals[1] * weights.y + triangle.normals[2] * weights.z)
            let reference: SIMD3<Float> = abs(normal.y) < 0.9 ? [0, 1, 0] : [1, 0, 0]
            let tangent = simd_normalize(simd_cross(normal, reference))
            let bitangent = simd_cross(normal, tangent)
            let angle = random.next() * 2 * Float.pi
            let side = tangent * cos(angle) + bitangent * sin(angle)
            let lean = simd_cross(side, normal) * (random.next() - 0.5)
            let upward = SIMD3<Float>(0, 1, 0) - normal * normal.y
            let height = size * (0.035 + random.next() * 0.035)
            let width = size * (0.003 + random.next() * 0.002)
            let direction = simd_normalize(normal + upward * 0.85 + lean)
            let base = root + normal * size * 0.0006
            let middle = base + direction * height * 0.55
            let tip = base + direction * height + (upward * 0.18 + lean * 0.2) * height
            let vertex = UInt32(positions.count)
            positions += [base - side * width, base + side * width,
                          middle - side * width * 0.55, middle + side * width * 0.55, tip]
            // Soft normals keep each small blade from looking like a hard plastic shard.
            normals += Array(repeating: simd_normalize(normal + direction), count: 5)
            let shade = random.next()
            coordinates += [[shade, 0], [shade, 0], [shade, 0.55], [shade, 0.55], [shade, 1]]
            indices += [vertex, vertex + 1, vertex + 2, vertex + 1, vertex + 3, vertex + 2,
                        vertex + 2, vertex + 3, vertex + 4]
        }
        var descriptor = MeshDescriptor(name: "Batched grass blades")
        descriptor.positions = .init(positions)
        descriptor.normals = .init(normals)
        descriptor.textureCoordinates = .init(coordinates)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }
}
