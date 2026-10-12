enum NewAlarmStep: Int, CaseIterable {
    case time, repeatDays, snooze, exitPoint

    var title: String {
        switch self {
        case .time: "Time"
        case .repeatDays: "Repeat"
        case .snooze: "Snooze"
        case .exitPoint: "Exit point"
        }
    }

    var subtitle: String {
        switch self {
        case .time: "24-hour time"
        case .repeatDays: "Leave empty to ring once."
        case .snooze: "Choose how long to snooze."
        case .exitPoint: "Choose how you'll stop your alarm."
        }
    }

    var next: Self? { Self(rawValue: rawValue + 1) }
    var previous: Self? { Self(rawValue: rawValue - 1) }
}
