import RealityKit
import simd

/// A simple faceted silhouette: one plump body, a beak and tail, and two tapered wings.
@MainActor
enum ClockBirdMesh {
    private static var cached: (body: MeshResource, wing: MeshResource)?

    static func load() throws -> (body: MeshResource, wing: MeshResource) {
        if let cached { return cached }
        // Three octagonal sections form one continuous body, with no overlapping blocks.
        // +X points toward the beak; coordinates are scaled only when building the mesh.
        let sections: [(x: Float, y: Float, height: Float, width: Float)] = [
            (-3.5, -0.5, 3, 2.4), (0, 0, 4.2, 3.3), (3, 1.7, 2.8, 2.4)
        ]
        var points: [SIMD3<Float>] = []
        var faces: [[Int]] = []
        for section in sections {
            for index in 0..<8 {
                let angle = Float(index) * .pi / 4
                points.append([section.x, section.y + cos(angle) * section.height,
                               sin(angle) * section.width])
            }
        }
        for section in 0..<2 {
            for index in 0..<8 {
                let next = (index + 1) % 8
                let start = section * 8
                faces.append([start + index, start + next, start + next + 8, start + index + 8])
            }
        }
        points += [[-4.5, -0.5, 0], [4, 1.7, 0]]
        for index in 0..<8 {
            let next = (index + 1) % 8
            faces.append([24, next, index])
            faces.append([25, 16 + index, 16 + next])
        }
        // Two small triangular prisms keep the silhouette readable without facial detail.
        appendPrism([SIMD3(3.6, 2.4, -0.6), [3.6, 1.1, -0.6], [6, 1.7, -0.6]],
                    extrusion: [0, 0, 1.2], points: &points, faces: &faces)
        appendPrism([SIMD3(-3, -1, -0.9), [-7, -0.5, -0.9], [-7, -2, -0.9]],
                    extrusion: [0, 0, 1.8], points: &points, faces: &faces)
        let body = try mesh(name: "Clock bird body", points: points, faces: faces)

        points = []
        faces = []
        appendPrism([SIMD3(1, -0.3, 0), [-2, -0.3, 0], [-4, -0.3, 7]],
                    extrusion: [0, 0.6, 0], points: &points, faces: &faces)
        let wing = try mesh(name: "Clock bird wing", points: points, faces: faces)
        let result = (body: body, wing: wing)
        cached = result
        return result
    }

    private static func appendPrism(_ triangle: [SIMD3<Float>], extrusion: SIMD3<Float>,
                                    points: inout [SIMD3<Float>], faces: inout [[Int]]) {
        let start = points.count
        points += triangle + triangle.map { $0 + extrusion }
        // The triangle winds toward the extrusion; reverse the near cap.
        let prismFaces = [[2, 1, 0], [3, 4, 5], [0, 1, 4, 3], [1, 2, 5, 4], [2, 0, 3, 5]]
        faces += prismFaces.map { face in face.map { $0 + start } }
    }

    private static func mesh(name: String, points: [SIMD3<Float>], faces: [[Int]]) throws -> MeshResource {
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
