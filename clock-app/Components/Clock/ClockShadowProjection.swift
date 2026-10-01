import simd

/// Oblique projection onto the flat backdrop, factored into ordinary transforms.
/// The small nonzero Z scale keeps normal transforms invertible.
struct ClockShadowProjection {
    static let backdropDepth: Float = -0.04
    let position: SIMD3<Float>
    let rotation: simd_quatf
    let scale: SIMD3<Float>
    let counterRotation: simd_quatf

    init(direction: Double, length: Double) {
        let azimuth = Float(direction * .pi / 180)
        let tilt = Float(length * .pi / 180)
        let slope = SIMD2(cos(azimuth), sin(azimuth)) * tan(tilt)
        position = [Self.backdropDepth * slope.x, Self.backdropDepth * slope.y,
                    Self.backdropDepth + 0.001]
        rotation = simd_quatf(angle: azimuth, axis: [0, 0, 1])
        scale = [1 / cos(tilt), 1, 0.00001]
        counterRotation = simd_quatf(angle: -tilt, axis: [0, 1, 0])
            * simd_quatf(angle: -azimuth, axis: [0, 0, 1])
    }
}
