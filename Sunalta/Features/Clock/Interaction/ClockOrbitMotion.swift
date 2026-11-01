import simd

/// Shared drag limits and spring motion, measured relative to each clock's resting angle.
nonisolated struct ClockOrbitMotion {
    let restingAngles: SIMD2<Float>
    let maximumAngle: Float = .pi / 7
    private(set) var offset = SIMD2<Float>.zero
    private(set) var velocity = SIMD2<Float>.zero
    private var dragOrigin = SIMD2<Float>.zero

    init(restingAngles: SIMD2<Float> = .zero) {
        self.restingAngles = restingAngles
    }

    var angles: SIMD2<Float> { restingAngles + offset }

    var orientation: simd_quatf {
        simd_quatf(angle: angles.x, axis: [0, 1, 0])
            * simd_quatf(angle: angles.y, axis: [1, 0, 0])
    }

    mutating func beginDrag() {
        velocity = .zero
        dragOrigin = offset
    }

    mutating func drag(translation: SIMD2<Float>, width: Float) {
        let proposed = dragOrigin + angularMotion(translation, width: width)
        offset = simd_clamp(proposed, SIMD2(repeating: -maximumAngle), SIMD2(repeating: maximumAngle))
    }

    mutating func release(velocity: SIMD2<Float>, width: Float) {
        self.velocity = simd_clamp(angularMotion(velocity, width: width),
                                   SIMD2(repeating: -1.5), SIMD2(repeating: 1.5))
    }

    /// Returns true once the spring has settled exactly at the configured resting angle.
    mutating func advance(by elapsed: Float) -> Bool {
        let duration = min(max(elapsed, 0), 1.0 / 30)
        let steps = max(1, Int((duration / (1.0 / 240)).rounded(.up)))
        let dt = duration / Float(steps)
        for _ in 0..<steps {
            velocity += (-150 * offset - 19 * velocity) * dt
            offset += velocity * dt
        }
        if simd_length(offset) < 0.001 && simd_length(velocity) < 0.01 {
            reset()
            return true
        }
        return false
    }

    mutating func reset() {
        offset = .zero
        velocity = .zero
        dragOrigin = .zero
    }

    private func angularMotion(_ movement: SIMD2<Float>, width: Float) -> SIMD2<Float> {
        SIMD2(-movement.x, movement.y) * (maximumAngle / max(width * 0.45, 1))
    }
}
