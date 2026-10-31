import Foundation

struct ClockWidgetPreferencesStore {
    private static let key = "clockWidgetPreferencesV1"
    let defaults: UserDefaults

    func load() -> ClockWidgetPreferences {
        guard let data = defaults.data(forKey: Self.key),
              let preferences = try? JSONDecoder().decode(ClockWidgetPreferences.self, from: data) else {
            return ClockWidgetPreferences()
        }
        return preferences
    }

    /// Write one complete snapshot and avoid spending reloads on unchanged preferences.
    @discardableResult
    func save(_ preferences: ClockWidgetPreferences) throws -> Bool {
        if let existing = defaults.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode(ClockWidgetPreferences.self, from: existing),
           saved == preferences { return false }
        let data = try JSONEncoder().encode(preferences)
        defaults.set(data, forKey: Self.key)
        return true
    }
}
