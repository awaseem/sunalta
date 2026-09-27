import Foundation

enum ClockWeekday: Int, CaseIterable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    init(date: Date, calendar: Calendar = .autoupdatingCurrent) {
        self = Self(rawValue: calendar.component(.weekday, from: date)) ?? .sunday
    }

    var abbreviation: String {
        switch self {
        case .sunday: "Sun"
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        }
    }

    var symbol: String {
        switch self {
        case .sunday: "☉"
        case .monday: "☽"
        case .tuesday: "♂"
        case .wednesday: "☿"
        case .thursday: "♃"
        case .friday: "♀"
        case .saturday: "♄"
        }
    }

    var name: String {
        switch self {
        case .sunday: "Sunday"
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        }
    }
}
