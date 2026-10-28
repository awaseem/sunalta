import Foundation

/// Presentation only: alarm storage and scheduling always use hours 0...23.
nonisolated struct ClockTimeDisplay: Equatable {
    /// Four ASCII mesh keys, including a leading zero in either format.
    let digits: String
    /// Localized, unambiguous time for labels and accessibility, regardless of decorative label visibility.
    let text: String
    let period: String?

    init(date: Date, format: ClockTimeFormat, calendar: Calendar = .autoupdatingCurrent,
         locale: Locale = .autoupdatingCurrent) {
        self.init(hour: calendar.component(.hour, from: date),
                  minute: calendar.component(.minute, from: date), format: format, locale: locale)
    }

    init(hour: Int, minute: Int, format: ClockTimeFormat, locale: Locale = .autoupdatingCurrent) {
        let displayHour = format == .twelveHour ? (hour + 11) % 12 + 1 : hour
        let digitStyle = IntegerFormatStyle<Int>.number.grouping(.never)
            .precision(.integerLength(2)).locale(Locale(identifier: "en_US_POSIX"))
        digits = "\(displayHour.formatted(digitStyle)):\(minute.formatted(digitStyle))"

        // A fixed UTC day formats wall-clock components without a DST gap or calendar conversion.
        let date = Date(timeIntervalSinceReferenceDate: TimeInterval(hour * 3600 + minute * 60))
        let locale = format.locale(overriding: locale)
        text = date.formatted(Date.FormatStyle(date: .omitted, time: .shortened,
                                              locale: locale, timeZone: .gmt))
        period = format == .twelveHour ? date.formatted(Date.VerbatimFormatStyle(
            format: "\(dayPeriod: .standard(.abbreviated))", locale: locale,
            timeZone: .gmt, calendar: Calendar(identifier: .gregorian)
        )) : nil
    }
}
