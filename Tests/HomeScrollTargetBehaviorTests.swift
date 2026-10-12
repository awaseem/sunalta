import SwiftUI
import Testing
@testable import clock_app

struct HomeScrollTargetBehaviorTests {
    @Test(arguments: [CGFloat(940), 1_130, 1_675, 2_450])
    func alarmListKeepsItsNaturalStoppingPosition(proposedOffset: CGFloat) {
        let behavior = HomeScrollTargetBehavior(
            clockHeight: 800, hasPulledPastReturnThreshold: .constant(false), isPaging: false
        )

        #expect(behavior.destination(proposedOffset: proposedOffset, originalOffset: 1_200) == proposedOffset)
    }

    @Test(arguments: [false, true])
    func flingFromWithinAlarmsStopsAtListTop(hasPulledPastThreshold: Bool) {
        let behavior = HomeScrollTargetBehavior(
            clockHeight: 800,
            hasPulledPastReturnThreshold: .constant(hasPulledPastThreshold),
            isPaging: false
        )

        #expect(behavior.destination(proposedOffset: 0, originalOffset: 1_400) == 800)
    }

    @Test func shortFastPullAtListTopDoesNotReturnToClock() {
        let behavior = HomeScrollTargetBehavior(
            clockHeight: 800, hasPulledPastReturnThreshold: .constant(false), isPaging: false
        )

        #expect(behavior.destination(proposedOffset: 0, originalOffset: 800) == 800)
    }

    @Test func deliberatePullAtListTopReturnsToClock() {
        let behavior = HomeScrollTargetBehavior(
            clockHeight: 800, hasPulledPastReturnThreshold: .constant(true), isPaging: true
        )

        #expect(behavior.destination(proposedOffset: 500, originalOffset: 800) == 0)
    }

    @Test func reversingBackIntoAlarmsDoesNotReturnToClock() {
        let behavior = HomeScrollTargetBehavior(
            clockHeight: 800, hasPulledPastReturnThreshold: .constant(true), isPaging: true
        )

        #expect(behavior.destination(proposedOffset: 1_000, originalOffset: 800) == 1_000)
    }

    @Test func returnThresholdIsReadAtReleaseInsteadOfGestureStart() {
        var hasPassedThreshold = false
        let threshold = Binding(get: { hasPassedThreshold }, set: { hasPassedThreshold = $0 })
        let behavior = HomeScrollTargetBehavior(
            clockHeight: 800, hasPulledPastReturnThreshold: threshold, isPaging: true
        )

        hasPassedThreshold = true

        #expect(behavior.destination(proposedOffset: 0, originalOffset: 800) == 0)
    }
}
