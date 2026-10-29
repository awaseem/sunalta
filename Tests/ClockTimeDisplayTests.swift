import Foundation
import Testing
@testable import clock_app

struct ClockTimeDisplayTests {
    private let locale = Locale(identifier: "en_US")

    @Test(arguments: [
        (0, 0, "12:00", "AM"),
        (11, 59, "11:59", "AM"),
        (12, 0, "12:00", "PM"),
        (13, 30, "01:30", "PM"),
        (23, 59, "11:59", "PM")
    ])
    func twelveHourTimeHandlesMidnightNoonAndAfternoon(
        hour: Int, minute: Int, digits: String, period: String
    ) {
        let display = ClockTimeDisplay(hour: hour, minute: minute, format: .twelveHour, locale: locale)
        #expect(display.digits == digits)
        #expect(display.period == period)
        #expect(display.text.hasSuffix(period))
    }

    @Test(arguments: [(0, 0, "00:00"), (7, 5, "07:05"), (12, 0, "12:00"), (23, 59, "23:59")])
    func twentyFourHourTimeKeepsMidnightAndLeadingZerosWithoutAPeriod(hour: Int, minute: Int, expected: String) {
        let display = ClockTimeDisplay(hour: hour, minute: minute, format: .twentyFourHour, locale: locale)
        #expect(display.digits == expected)
        #expect(display.text == expected)
        #expect(display.period == nil)
    }

    @Test func periodAndDigitsUseTheSameLocalCalendarAcrossMidnight() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: -6 * 60 * 60))
        let date = try Date("2026-10-28T03:30:00Z", strategy: .iso8601)
        let display = ClockTimeDisplay(date: date, format: .twelveHour, calendar: calendar, locale: locale)
        #expect(display.digits == "09:30")
        #expect(display.period == "PM")
    }

    @Test func localizedLabelsDoNotReplaceTheASCIIMeshKeys() {
        let display = ClockTimeDisplay(hour: 16, minute: 8, format: .twelveHour,
                                       locale: Locale(identifier: "ar_SA"))
        #expect(display.digits == "04:08")
        #expect(display.text.contains("٤:٠٨"))
        #expect(display.period == "م")
    }
}
