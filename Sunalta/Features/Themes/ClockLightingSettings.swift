import Foundation

struct ClockLightingSettings: Codable, Equatable {
    var direction = 180.0
    var tilt = 50.24
    var strength = 2600.0
    var fill = 0.0

    var lightPosition: SIMD3<Float> {
        let azimuth = direction * .pi / 180
        let tilt = self.tilt * .pi / 180
        return SIMD3(Float(cos(azimuth) * sin(tilt)),
                     Float(sin(azimuth) * sin(tilt)), Float(cos(tilt))) * 10
    }
}
