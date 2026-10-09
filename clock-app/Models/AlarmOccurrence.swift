import Foundation

/// Calendar calculations are independent of SwiftData and use an explicit calendar.
nonisolated enum AlarmOccurrence {
    static func latest(hour: Int, minute: Int, repeatDays: Set<ClockWeekday>,
                       before date: Date, calendar: Calendar) -> Date? {
        let weekdays: [Int?] = repeatDays.isEmpty ? [nil] : repeatDays.map { $0.rawValue }
        return weekdays.compactMap { weekday in
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            components.second = 0
            components.weekday = weekday
            return calendar.nextDate(after: date, matching: components,
                                     matchingPolicy: .nextTime, direction: .backward)
        }.max()
    }
}
