import simd
import Testing
@testable import Sunalta

struct ClockFlybyPathTests {
    @Test(arguments: [true, false])
    func birdFadesInWithinViewportAndExitsOnChosenSide(travelsRight: Bool) {
        let path = ClockFlybyPath(duration: 4, travelsRight: travelsRight, height: 0.2, arc: 0.15)
        for viewport in [SIMD2<Float>(6, 14), SIMD2<Float>(20, 14)] {
            let entry = path.position(at: 0, viewport: viewport, cameraDistance: 66)
            #expect(abs(entry.x * 66 / -entry.z) < viewport.x / 2)
            let exit = path.position(at: path.duration, viewport: viewport, cameraDistance: 66)
            let projectedX = exit.x * 66 / -exit.z
            #expect(travelsRight ? projectedX > viewport.x / 2 : projectedX < -viewport.x / 2)
        }
        #expect(path.opacity(at: 0) == 0)
        #expect(path.opacity(at: 2) > 0)
        #expect(path.opacity(at: path.duration) == 0)
    }

    @Test func birdNeverCrossesInFrontOfNumeralsOrBehindBackdrop() {
        let path = ClockFlybyPath(duration: 4, travelsRight: true, height: 0, arc: 0.1)
        let viewport = SIMD2<Float>(6, 14)
        let start = path.position(at: 0, viewport: viewport, cameraDistance: 66)
        for frame in 0...120 {
            let position = path.position(at: Double(frame) / 30, viewport: viewport, cameraDistance: 66)
            #expect(position.z < -66)
            #expect(position.z > -66 + ClockFlybyPath.backdropDepth)
            #expect(position.z == start.z)
        }
        // A delayed frame must finish at the exit rather than wrapping back onto the screen.
        #expect(path.position(at: 20, viewport: viewport, cameraDistance: 66)
                == path.position(at: 4, viewport: viewport, cameraDistance: 66))
        #expect(path.opacity(at: 20) == 0)
    }

    @Test(arguments: [true, false])
    func beakFollowsFlightWithoutFlippingUpsideDown(travelsRight: Bool) {
        let path = ClockFlybyPath(duration: 4, travelsRight: travelsRight, height: 0.2, arc: 0.15)
        let viewport = SIMD2<Float>(6, 14)
        for frame in 0...120 {
            let elapsed = Double(frame) / 30
            let orientation = path.orientation(at: elapsed, viewport: viewport, cameraDistance: 66)
            let before = path.position(at: max(0, elapsed - 0.01), viewport: viewport, cameraDistance: 66)
            let after = path.position(at: min(4, elapsed + 0.01), viewport: viewport, cameraDistance: 66)
            let direction = simd_normalize(after - before)
            #expect(simd_dot(orientation.act([1, 0, 0]), direction) > 0.999)
            #expect(orientation.act([0, 1, 0]).y > 0)
        }
    }
}
