/// Optional fields preserve authored defaults and decode existing size/weight settings.
struct ClockWeekdayAdjustments: Codable, Equatable {
    var size: Double?
    var weight: ClockWeekdayWeight?
    var glow: ClockWeekdayGlowSettings?

    func applying(to appearance: ClockWeekdayAppearance) -> ClockWeekdayAppearance {
        var result = appearance
        if let size { result.size = size }
        if let weight { result.weight = weight }
        if let glow { result.glow = glow }
        return result
    }
}
