import Foundation
import Testing
@testable import clock_app

@MainActor
struct ClockDisplaySettingsTests {
    @Test func missingOrUnknownPreferenceDefaultsToTwentyFourHours() throws {
        let suite = "ClockSettingsTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        #expect(ClockDisplaySettings(defaults: defaults).format == .twentyFourHour)
        defaults.set("unsupported", forKey: "clockTimeFormat")
        #expect(ClockDisplaySettings(defaults: defaults).format == .twentyFourHour)
    }

    @Test func explicitPreferenceSurvivesRelaunchAndPeriodChoiceSurvivesTwentyFourHourMode() throws {
        let suite = "ClockSettingsTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = ClockDisplaySettings(defaults: defaults)
        settings.showsPeriod = false
        settings.format = .twentyFourHour
        let relaunched = ClockDisplaySettings(defaults: defaults)
        #expect(relaunched.format == .twentyFourHour)
        relaunched.format = .twelveHour
        #expect(!relaunched.showsPeriod)
        #expect(ClockDisplaySettings(defaults: defaults).format == .twelveHour)
    }
}
