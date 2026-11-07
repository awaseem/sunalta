import Foundation

enum AlarmRepeatSummary {
    static var orderedDays: [ClockWeekday] {
        let first = Calendar.autoupdatingCurrent.firstWeekday
        return (0..<7).compactMap { ClockWeekday(rawValue: (first - 1 + $0) % 7 + 1) }
    }

    static func text(for days: Set<ClockWeekday>) -> String {
        if days.isEmpty { return "Once" }
        if days.count == 7 { return "Every day" }
        if days == [.monday, .tuesday, .wednesday, .thursday, .friday] { return "Weekdays" }
        if days == [.saturday, .sunday] { return "Weekends" }
        return orderedDays.filter { days.contains($0) }.map(\.abbreviation).joined(separator: ", ")
    }
}
