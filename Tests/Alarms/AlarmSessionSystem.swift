import AlarmKit
import Foundation
@testable import Sunalta

@MainActor
final class AlarmSessionSystem {
    var states: [UUID: Alarm.State] = [:]
    var snoozeFails = false
    var recurringIDs: Set<UUID> = []

    var operations: AlarmRuntimeSystem {
        .init(states: { self.states }, snooze: { id in
            if self.snoozeFails { throw CocoaError(.featureUnsupported) }
            self.states[id] = .countdown
        }, silence: { id in
            self.states[id] = self.recurringIDs.contains(id) ? .scheduled : nil
        }, scheduleCountdown: { _, id, _, _ in
            self.states[id] = .countdown
        })
    }
}
