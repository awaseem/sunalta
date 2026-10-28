enum AlarmEditorStep: Int, CaseIterable {
    case time, repeatDays, snooze, exitPoint, name

    var title: String {
        switch self {
        case .time: "Time"
        case .repeatDays: "Repeat"
        case .snooze: "Snooze"
        case .exitPoint: "Exit point"
        case .name: "Name & sound"
        }
    }

    var subtitle: String {
        switch self {
        case .time: "Choose when your alarm rings."
        case .repeatDays: "Leave empty to ring once."
        case .snooze: "Choose how long to snooze."
        case .exitPoint: "Choose how you'll stop your alarm."
        case .name: "Give your alarm a name, or leave it blank."
        }
    }

    var next: Self? { Self(rawValue: rawValue + 1) }
    var previous: Self? { Self(rawValue: rawValue - 1) }
}
