import SwiftData
import SwiftUI

struct ClockAlarmHint: View {
    @Environment(\.calendar) private var calendar
    @Query(filter: #Predicate<AlarmRecord> { $0.isEnabled }) private var alarms: [AlarmRecord]
    let isActive: Bool

    var body: some View {
        TimelineView(.everyMinute) { context in
            let nextAlarm = alarms.compactMap {
                $0.nextOccurrence(after: context.date, calendar: calendar)
            }.min()

            ClockAlarmHintContent(nextAlarm: nextAlarm, now: context.date, isActive: isActive)
        }
    }
}
