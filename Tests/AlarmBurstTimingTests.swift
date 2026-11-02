import Testing
@testable import Sunalta

struct AlarmBurstTimingTests {
    @Test func firesOnceAtEachEndOfTheVisibleSwing() {
        var timing = AlarmBurstTiming(swingDuration: 2.4)
        let bursts = [0.59, 0.61, 0.7, 1.81, 3.01].map { timing.advance(by: 0, bellTime: $0) }
        #expect(bursts == [false, true, false, true, true])
    }

    @Test func passiveCadenceContinuesWhenTheBellRests() {
        var timing = AlarmBurstTiming(swingDuration: 2.4)
        let firstBurst = timing.advance(by: 0, bellTime: 0.61)
        let restingBursts = [1, 0.2, 0.1].map { timing.advance(by: $0, bellTime: nil) }
        #expect(firstBurst)
        #expect(restingBursts == [false, true, false])
    }

    @Test func restartingTheBellDoesNotReplayMissedBursts() {
        var timing = AlarmBurstTiming(swingDuration: 2.4)
        let lateFrame = timing.advance(by: 4, bellTime: nil)
        let restartedBursts = [0, 0.2, 0.61, 0.61].map { timing.advance(by: 0, bellTime: $0) }
        #expect(lateFrame)
        #expect(restartedBursts == [false, false, true, false])
    }
}
