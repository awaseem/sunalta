import Foundation
import Testing
@testable import clock_app

struct ClockWidgetScheduleTests {
    @Test func firstUpdateIsTheNextWholeMinuteEvenAcrossMidnight() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let now = try Date("2026-10-29T23:59:47Z", strategy: .iso8601)
        let schedule = ClockWidgetSchedule(now: now, calendar: calendar)
        #expect(schedule.dates[0] == now)
        #expect(schedule.dates[1] == (try Date("2026-10-30T00:00:00Z", strategy: .iso8601)))
        #expect(schedule.dates.last == (try Date("2026-10-30T05:59:00Z", strategy: .iso8601)))
        #expect(schedule.refreshDate < (try #require(schedule.dates.last)))
    }

    @Test(arguments: ["2026-03-08T08:59:00Z", "2026-11-01T07:59:00Z"])
    func daylightSavingChangesKeepEntriesStrictlyIncreasingWithoutDuplicateBoundary(_ timestamp: String) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Edmonton"))
        let now = try Date(timestamp, strategy: .iso8601)
        let schedule = ClockWidgetSchedule(now: now, calendar: calendar)
        for (earlier, later) in zip(schedule.dates, schedule.dates.dropFirst()) {
            #expect(later.timeIntervalSince(earlier) == 60)
        }
    }
}
