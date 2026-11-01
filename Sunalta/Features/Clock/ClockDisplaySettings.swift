import Foundation
import Observation

@MainActor
@Observable
final class ClockDisplaySettings {
    private let defaults: UserDefaults
    private static let formatKey = "clockTimeFormat"
    private static let periodKey = "showClockPeriod"

    var format: ClockTimeFormat {
        didSet { defaults.set(format.rawValue, forKey: Self.formatKey) }
    }
    var showsPeriod: Bool {
        didSet { defaults.set(showsPeriod, forKey: Self.periodKey) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        format = defaults.string(forKey: Self.formatKey).flatMap(ClockTimeFormat.init(rawValue:))
            ?? .twentyFourHour
        showsPeriod = defaults.object(forKey: Self.periodKey) == nil || defaults.bool(forKey: Self.periodKey)
    }
}
