import AlarmKit
import Foundation

extension AlarmRecord {
    func alarmKitSchedule() throws -> Alarm.Schedule {
        try validate()
        let weekdays = repeatDays.sorted { $0.rawValue < $1.rawValue }.map(\.alarmKitWeekday)
        return .relative(.init(
            time: .init(hour: hour, minute: minute),
            repeats: weekdays.isEmpty ? .never : .weekly(weekdays)
        ))
    }
}

private nonisolated extension ClockWeekday {
    var alarmKitWeekday: Locale.Weekday {
        switch self {
        case .sunday: .sunday
        case .monday: .monday
        case .tuesday: .tuesday
        case .wednesday: .wednesday
        case .thursday: .thursday
        case .friday: .friday
        case .saturday: .saturday
        }
    }
}
