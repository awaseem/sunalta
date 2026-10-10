import simd
import Testing
@testable import clock_app

struct ClockOrbitMotionTests {
    @Test(arguments: [SIMD2<Float>.zero, SIMD2<Float>(0.12, -0.22)])
    func releasedDragReturnsToItsOwnRestingAngle(restingAngles: SIMD2<Float>) {
        var motion = ClockOrbitMotion(restingAngles: restingAngles)
        motion.beginDrag()
        motion.drag(translation: [130, -40], width: 354)
        motion.release(velocity: [700, -150], width: 354)
        var settled = false
        for _ in 0..<240 {
            if motion.advance(by: 1.0 / 60) {
                settled = true
                break
            }
        }
        #expect(settled)
        #expect(motion.angles == restingAngles)
        #expect(motion.velocity == .zero)
    }

    @Test func grabbingDuringReturnDoesNotJump() {
        var motion = ClockOrbitMotion(restingAngles: [0.12, -0.22])
        motion.beginDrag()
        motion.drag(translation: [100, 30], width: 354)
        motion.release(velocity: [200, 30], width: 354)
        _ = motion.advance(by: 1.0 / 60)
        let interruptedAngles = motion.angles
        motion.beginDrag()
        motion.drag(translation: .zero, width: 354)
        #expect(motion.angles == interruptedAngles)
        #expect(motion.velocity == .zero)
    }

    @Test func relativeDragsFeelTheSameAtDifferentViewSizes() {
        var small = ClockOrbitMotion()
        var large = ClockOrbitMotion()
        small.beginDrag()
        large.beginDrag()
        small.drag(translation: [50, -20], width: 200)
        large.drag(translation: [100, -40], width: 400)
        #expect(small.offset == large.offset)
    }

    @Test func limitsAndImmediateResetAreRelativeToRestingAngle() {
        let restingAngles = SIMD2<Float>(0.12, -0.22)
        var motion = ClockOrbitMotion(restingAngles: restingAngles)
        motion.beginDrag()
        motion.drag(translation: [10_000, -10_000], width: 354)
        #expect(motion.offset == SIMD2(repeating: -motion.maximumAngle))
        motion.reset()
        #expect(motion.angles == restingAngles)
        #expect(motion.velocity == .zero)
    }
}
