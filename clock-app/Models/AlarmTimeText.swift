import Foundation

/// ASCII 24-hour digits are also the keys used by the sculpted clock meshes.
nonisolated enum AlarmTimeText {
    static func text(hour: Int, minute: Int) -> String {
        let style = IntegerFormatStyle<Int>.number
            .grouping(.never)
            .precision(.integerLength(2))
            .locale(Locale(identifier: "en_US_POSIX"))
        return "\(hour.formatted(style)):\(minute.formatted(style))"
    }
}
