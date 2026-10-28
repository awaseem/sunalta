import Foundation

nonisolated enum ClockTimeFormat: String {
    case twelveHour = "12-hour"
    case twentyFourHour = "24-hour"

    /// Preserve language, region, and numbering while choosing an explicit hour cycle.
    func locale(overriding locale: Locale) -> Locale {
        var components = Locale.Components(identifier: locale.identifier)
        components.hourCycle = self == .twelveHour ? .oneToTwelve : .zeroToTwentyThree
        return Locale(components: components)
    }
}
