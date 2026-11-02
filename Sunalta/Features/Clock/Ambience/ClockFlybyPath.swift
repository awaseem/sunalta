import simd

/// Camera-relative flight, parameterized by elapsed time so delayed frames cannot accumulate drift.
nonisolated struct ClockFlybyPath {
    // The entire bird stays between the backs of the numerals and the backdrop.
    static let depth: Float = -1.4
    static let backdropDepth: Float = -3
    let duration: Double
    let travelsRight: Bool
    let height: Float
    let arc: Float
    var origin: Float = 0
    var horizontalReach: Float = 1.25

    func position(at elapsed: Double, viewport: SIMD2<Float>, cameraDistance: Float) -> SIMD3<Float> {
        let progress = Float(min(max(elapsed / duration, 0), 1))
        let distance = cameraDistance - Self.depth
        let perspective = distance / cameraDistance
        let direction: Float = travelsRight ? 1 : -1
        // Begin near the middle, then gradually veer toward the chosen edge.
        let bend = 0.2 * progress + 0.8 * progress * progress
        let x = origin + (direction * horizontalReach - origin) * bend
        let y = height + arc * sin(.pi * progress / 2)
        return [x * viewport.x / 2 * perspective,
                y * viewport.y / 2 * perspective,
                -distance]
    }

    func opacity(at elapsed: Double) -> Float {
        0.88 * visibility(at: elapsed)
    }

    /// A normalized fade shared by the visual opacity and the flight's audio level.
    func visibility(at elapsed: Double) -> Float {
        let progress = Float(min(max(elapsed / duration, 0), 1))
        let fadeIn = smoothstep(progress / 0.24)
        let fadeOut = smoothstep((1 - progress) / 0.22)
        return fadeIn * fadeOut
    }

    private func smoothstep(_ value: Float) -> Float {
        let value = min(max(value, 0), 1)
        return value * value * (3 - 2 * value)
    }

    func orientation(at elapsed: Double, viewport: SIMD2<Float>, cameraDistance: Float) -> simd_quatf {
        let progress = min(max(elapsed, 0), duration)
        let before = position(at: max(0, progress - 0.01), viewport: viewport, cameraDistance: cameraDistance)
        let after = position(at: min(duration, progress + 0.01), viewport: viewport, cameraDistance: cameraDistance)
        let tangent = simd_normalize(after - before)
        // Keep the bird upright while its beak follows the curve toward either edge.
        let yaw = atan2(-tangent.z, tangent.x)
        let pitch = asin(tangent.y)
        return simd_quatf(angle: yaw, axis: [0, 1, 0])
            * simd_quatf(angle: pitch, axis: [0, 0, 1])
    }
}
