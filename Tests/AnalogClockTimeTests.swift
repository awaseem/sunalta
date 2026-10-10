import Foundation
import Testing
@testable import clock_app

struct AnalogClockTimeTests {
    @Test func handsUseMinutePrecision() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let date = try #require(calendar.date(from: DateComponents(
            year: 2026, month: 10, day: 10, hour: 15, minute: 15, second: 30
        )))
        let time = AnalogClockTime(date: date, calendar: calendar)
        #expect(abs(time.hourAngle - Float(97.5 * Double.pi / 180)) < 0.00001)
        #expect(abs(time.minuteAngle - .pi / 2) < 0.00001)
    }

    @Test func midnightAndNoonBothPointToTwelve() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        for hour in [0, 12] {
            let date = try #require(calendar.date(from: DateComponents(
                year: 2026, month: 10, day: 10, hour: hour, minute: 0, second: 0
            )))
            let time = AnalogClockTime(date: date, calendar: calendar)
            #expect(time.hourAngle == 0)
            #expect(time.minuteAngle == 0)
        }
    }

    @Test func handsUseTheInjectedTimeZone() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 5 * 3600 + 30 * 60))
        let time = AnalogClockTime(date: Date(timeIntervalSince1970: 0), calendar: calendar)
        #expect(abs(time.hourAngle - Float(165 * Double.pi / 180)) < 0.00001)
        #expect(abs(time.minuteAngle - .pi) < 0.00001)
    }
}
