import Foundation

nonisolated struct ClockWidgetSchedule {
    let dates: [Date]
    let refreshDate: Date

    init(now: Date, calendar: Calendar = .autoupdatingCurrent) {
        let minuteStart = calendar.dateInterval(of: .minute, for: now)?.start ?? now
        // Supply six hours of minute entries in one request, with an hourly refill.
        // Absolute intervals cross midnight and DST without repeating or skipping instants.
        dates = [now] + (1...360).map { minuteStart.addingTimeInterval(TimeInterval($0 * 60)) }
        refreshDate = now.addingTimeInterval(60 * 60)
    }
}
