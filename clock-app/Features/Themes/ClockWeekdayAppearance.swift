struct ClockWeekdayAppearance: Encodable, Equatable {
    static let sizeRange = 12.0...64.0

    var size = 40.16969585418701
    var weight = ClockWeekdayWeight.medium
    var glow = ClockWeekdayGlowSettings()
}
