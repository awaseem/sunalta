import Foundation

struct NewAlarmDraft {
    var time = Calendar.autoupdatingCurrent.date(
        from: DateComponents(year: 2001, month: 1, day: 1, hour: 7, minute: 0)
    ) ?? .now
    var repeatDays: Set<ClockWeekday> = []
    var snoozeEnabled = true
    var snoozeMinutes = 10
    var exitPoint = AlarmExitPointDraft()

    func timeComponents(calendar: Calendar = .autoupdatingCurrent) -> DateComponents {
        calendar.dateComponents([.hour, .minute], from: time)
    }

    var displayTime: String {
        let components = timeComponents()
        return AlarmTimeText.text(hour: components.hour ?? 7, minute: components.minute ?? 0)
    }
}
