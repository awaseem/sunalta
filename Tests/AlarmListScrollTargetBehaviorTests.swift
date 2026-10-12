import SwiftUI
import Testing
@testable import clock_app

struct AlarmListScrollTargetBehaviorTests {
    @Test(arguments: [CGFloat(940), 1_130, 1_675, 2_450])
    func alarmListKeepsItsNaturalStoppingPosition(proposedOffset: CGFloat) {
        let behavior = AlarmListScrollTargetBehavior(topOffset: 800)

        #expect(behavior.destination(proposedOffset: proposedOffset) == proposedOffset)
    }

    @Test func momentumFromWithinAlarmsStopsAtListTop() {
        let behavior = AlarmListScrollTargetBehavior(topOffset: 800)

        #expect(behavior.destination(proposedOffset: 0) == 800)
    }
}
