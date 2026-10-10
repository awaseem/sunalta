struct ClockWeekdayAppearance: Encodable, Equatable {
    static let sizeRange = 12.0...64.0

    var size = 46.0
    var weight = ClockWeekdayWeight.semibold
    var glow = ClockWeekdayGlowSettings()
}
