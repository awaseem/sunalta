import RealityKit
import simd

/// Two rounded lobes on each wing and a slender body keep the butterfly silhouette distinct.
@MainActor
enum ClockButterflyMesh {
    private static var cached: (body: MeshResource, wing: MeshResource)?

    static func load() throws -> (body: MeshResource, wing: MeshResource) {
        if let cached { return cached }
        let sections: [(x: Float, height: Float, width: Float)] = [
            (-4.4, 0.18, 0.18), (-2.4, 0.48, 0.42),
            (0.7, 0.65, 0.52), (2.6, 0.5, 0.45)
        ]
        var points: [SIMD3<Float>] = []
        var faces: [[Int]] = []
        for section in sections {
            for index in 0..<8 {
                let angle = Float(index) * .pi / 4
                points.append([section.x, cos(angle) * section.height, sin(angle) * section.width])
            }
        }
        for section in 0..<(sections.count - 1) {
            for index in 0..<8 {
                let next = (index + 1) % 8
                let start = section * 8
                faces.append([start + index, start + next, start + next + 8, start + index + 8])
            }
        }
        faces += [Array((0..<8).reversed()), Array(24..<32)]
        for side in [Float(-1), 1] {
            // A narrow, bent ribbon makes each antenna without additional entities.
            let start = points.count
            points += [[2.5, 0.25, side * 0.3], [4.1, 0.5, side * 1.05], [5.2, 0.9, side * 1.8],
                       [5.25, 1.1, side * 1.8], [4.05, 0.7, side * 1.05], [2.45, 0.45, side * 0.3]]
            faces += [[0, 1, 4, 5], [1, 2, 3, 4], [5, 4, 1, 0], [4, 3, 2, 1]].map {
                $0.map { $0 + start }
            }
        }
        let body = try ClockFlybyMesh.make(name: "Clock butterfly body", points: points, faces: faces)

        points.removeAll(keepingCapacity: true)
        faces.removeAll(keepingCapacity: true)
        appendLobe(center: [1.7, 4.7], radii: [3.8, 5.3], angle: -0.25,
                   points: &points, faces: &faces)
        appendLobe(center: [-2.5, 3.1], radii: [3.1, 3.6], angle: 0.3,
                   points: &points, faces: &faces)
        let wing = try ClockFlybyMesh.make(name: "Clock butterfly wing", points: points, faces: faces)
        let result = (body: body, wing: wing)
        cached = result
        return result
    }

    private static func appendLobe(center: SIMD2<Float>, radii: SIMD2<Float>, angle: Float,
                                   points: inout [SIMD3<Float>], faces: inout [[Int]]) {
        let start = points.count
        let segments = 24
        points += [[center.x, 0.22, center.y], [center.x, -0.22, center.y]]
        for index in 0..<segments {
            let phase = Float(index) * 2 * .pi / Float(segments)
            let offset = SIMD2(cos(phase) * radii.x, sin(phase) * radii.y)
            let rotated = SIMD2(offset.x * cos(angle) - offset.y * sin(angle),
                                offset.x * sin(angle) + offset.y * cos(angle))
            let point = center + rotated
            points.append([point.x, 0, max(point.y, 0)])
        }
        for index in 0..<segments {
            let current = start + 2 + index
            let next = start + 2 + (index + 1) % segments
            faces += [[start, next, current], [start + 1, current, next]]
        }
    }
}
