import simd

@main
struct ClockShadowProjectionChecks {
    static func main() {
        var checked = 0
        for direction in stride(from: -180.0, through: 180.0, by: 15) {
            for length in [5.0, 25, 50.24, 75] {
                let projection = ClockShadowProjection(direction: direction, length: length)
                let azimuth = Float(direction * .pi / 180)
                let tilt = Float(length * .pi / 180)
                let ray = SIMD3(cos(azimuth) * sin(tilt), sin(azimuth) * sin(tilt), cos(tilt))
                for point: SIMD3<Float> in [[0, 0, 0], [2, 3, 0.7], [-3, -2, 0.025], [1, 1, -0.04]] {
                    let projected = projection.position + projection.rotation.act(
                        projection.scale * projection.counterRotation.act(point)
                    )
                    // Compare the factored entity transforms to ray/plane intersection.
                    let distance = (point.z - ClockShadowProjection.backdropDepth) / ray.z
                    let intersection = point - distance * ray
                    precondition(abs(projected.x - intersection.x) < 0.0001)
                    precondition(abs(projected.y - intersection.y) < 0.0001)
                    precondition(abs(projected.z - (ClockShadowProjection.backdropDepth + 0.001)) < 0.0001)
                    precondition(projected.z > ClockShadowProjection.backdropDepth)
                    checked += 1
                }
            }
        }
        print("Passed \(checked) shadow projection checks, including slider limits and points on the backdrop.")
    }
}
