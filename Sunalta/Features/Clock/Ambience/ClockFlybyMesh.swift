import RealityKit
import simd

/// Small faceted meshes shared by the themed flying animals.
@MainActor
enum ClockFlybyMesh {
    static func appendPrism(_ triangle: [SIMD3<Float>], extrusion: SIMD3<Float>,
                            points: inout [SIMD3<Float>], faces: inout [[Int]]) {
        let start = points.count
        points += triangle + triangle.map { $0 + extrusion }
        let prismFaces = [[2, 1, 0], [3, 4, 5], [0, 1, 4, 3], [1, 2, 5, 4], [2, 0, 3, 5]]
        faces += prismFaces.map { face in face.map { $0 + start } }
    }

    static func make(name: String, points: [SIMD3<Float>], faces: [[Int]]) throws -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        for face in faces {
            let normal = simd_normalize(simd_cross(points[face[1]] - points[face[0]],
                                                   points[face[2]] - points[face[0]]))
            let first = UInt32(positions.count)
            positions += face.map { points[$0] * 0.018 }
            normals += Array(repeating: normal, count: face.count)
            for index in 1..<(face.count - 1) {
                indices += [first, first + UInt32(index), first + UInt32(index + 1)]
            }
        }
        var descriptor = MeshDescriptor(name: name)
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }
}
