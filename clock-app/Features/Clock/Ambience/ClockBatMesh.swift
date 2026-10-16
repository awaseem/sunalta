import RealityKit
import simd

/// Pointed ears and a broad, scalloped membrane distinguish the bat from the daytime bird.
@MainActor
enum ClockBatMesh {
    private static var cached: (body: MeshResource, wing: MeshResource)?

    static func load() throws -> (body: MeshResource, wing: MeshResource) {
        if let cached { return cached }
        let sections: [(x: Float, y: Float, height: Float, width: Float)] = [
            (-3, 0, 1.2, 1.2), (-1, 0, 2.5, 1.7),
            (1.5, 0.3, 2.2, 1.7), (2.8, 0.6, 1.4, 1.2)
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
        for section in 0..<(sections.count - 1) {
            for index in 0..<8 {
                let next = (index + 1) % 8
                let start = section * 8
                faces.append([start + index, start + next, start + next + 8, start + index + 8])
            }
        }
        points += [[-3.7, 0, 0], [3.3, 0.6, 0]]
        for index in 0..<8 {
            let next = (index + 1) % 8
            faces.append([32, next, index])
            faces.append([33, 24 + index, 24 + next])
        }
        for side in [Float(-1), 1] {
            let z = side * 1.1 - 0.25
            ClockFlybyMesh.appendPrism(
                [[0.8, 1.6, z], [2.4, 1.6, z], [1.8, 4.8, z]],
                extrusion: [0, 0, 0.5], points: &points, faces: &faces
            )
        }
        let body = try ClockFlybyMesh.make(name: "Clock bat body", points: points, faces: faces)

        // The outline fans outward from the shoulder, with notches between the wing fingers.
        let outline: [SIMD3<Float>] = [
            [0, -0.15, 0], [2, -0.15, 2], [2.5, -0.15, 5.5], [1, -0.15, 9.5],
            [-0.5, -0.15, 7.4], [-1.4, -0.15, 7.3], [-2.7, -0.15, 8],
            [-2.2, -0.15, 5.9], [-2.3, -0.15, 5], [-4.2, -0.15, 5.5],
            [-3.4, -0.15, 4.1], [-3.5, -0.15, 3.3], [-5, -0.15, 2.3],
            [-3.1, -0.15, 1.3], [-2.5, -0.15, 0.8], [-2.4, -0.15, 0]
        ]
        let count = outline.count
        points = outline + outline.map { $0 + SIMD3(0, 0.3, 0) }
        faces = [Array(0..<count), Array((count..<(count * 2)).reversed())]
        for index in 0..<count {
            let next = (index + 1) % count
            faces.append([index, index + count, next + count, next])
        }
        let wing = try ClockFlybyMesh.make(name: "Clock bat wing", points: points, faces: faces)
        let result = (body: body, wing: wing)
        cached = result
        return result
    }
}
