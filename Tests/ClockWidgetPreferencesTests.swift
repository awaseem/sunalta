import Foundation
import Testing
@testable import clock_app

@MainActor
struct ClockWidgetPreferencesTests {
    @Test func independentReaderReceivesCompletePreferencesAndUnchangedWritesSkipReload() throws {
        let suite = "ClockWidgetTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let writer = ClockWidgetPreferencesStore(defaults: defaults)
        let reader = ClockWidgetPreferencesStore(defaults: try #require(UserDefaults(suiteName: suite)))
        var preferences = ClockWidgetPreferences(themeID: "midnight", timeFormat: .twelveHour,
                                                 showsPeriod: false)
        #expect(try writer.save(preferences))
        #expect(reader.load() == preferences)
        #expect(try !writer.save(preferences))
        preferences.themeID = "grass"
        #expect(try writer.save(preferences))
        #expect(reader.load() == preferences)
    }

    @Test func damagedSnapshotFallsBackAndCanBeRepairedWithDefaultPreferences() throws {
        let suite = "ClockWidgetTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("invalid".utf8), forKey: "clockWidgetPreferencesV1")
        let store = ClockWidgetPreferencesStore(defaults: defaults)
        #expect(store.load() == ClockWidgetPreferences())
        #expect(try store.save(ClockWidgetPreferences()))
        #expect(try !store.save(ClockWidgetPreferences()))
    }
}
