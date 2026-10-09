import Foundation
import Testing
@testable import clock_app

struct AlarmOccurrenceTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    @Test func dailyOccurrenceUsesThePreviousDayBeforeAlarmTime() throws {
        let before = try Date("2026-10-08T06:59:00Z", strategy: .iso8601)
        let expected = try Date("2026-10-07T07:00:00Z", strategy: .iso8601)
        #expect(AlarmOccurrence.latest(hour: 7, minute: 0, repeatDays: [],
                                       before: before, calendar: calendar) == expected)
    }

    @Test func weeklyOccurrenceSelectsTheLatestConfiguredDay() throws {
        let before = try Date("2026-10-08T08:00:00Z", strategy: .iso8601)
        let expected = try Date("2026-10-07T07:30:00Z", strategy: .iso8601)
        #expect(AlarmOccurrence.latest(hour: 7, minute: 30, repeatDays: [.monday, .wednesday],
                                       before: before, calendar: calendar) == expected)
    }

    @Test func occurrenceRespectsTheInjectedTimeZone() throws {
        var calendar = calendar
        calendar.timeZone = try #require(TimeZone(identifier: "America/Edmonton"))
        let before = try Date("2026-10-08T14:00:00Z", strategy: .iso8601)
        let expected = try Date("2026-10-08T13:00:00Z", strategy: .iso8601)
        #expect(AlarmOccurrence.latest(hour: 7, minute: 0, repeatDays: [],
                                       before: before, calendar: calendar) == expected)
    }

    @Test func springClockChangeKeepsAnOccurrenceForASkippedTime() throws {
        var calendar = calendar
        calendar.timeZone = try #require(TimeZone(identifier: "America/Edmonton"))
        let before = try Date("2026-03-08T11:00:00Z", strategy: .iso8601)
        let occurrence = try #require(AlarmOccurrence.latest(
            hour: 2, minute: 30, repeatDays: [.sunday], before: before, calendar: calendar
        ))
        let components = calendar.dateComponents([.month, .day, .hour, .minute], from: occurrence)
        #expect(components.month == 3 && components.day == 8)
        #expect(components.hour == 3 && components.minute == 0)
    }

    @Test(arguments: [(0, 0, "00:00"), (7, 5, "07:05"), (23, 59, "23:59")])
    func clockDigitsKeepLeadingZeros(hour: Int, minute: Int, expected: String) {
        #expect(AlarmTimeText.text(hour: hour, minute: minute) == expected)
    }
}
