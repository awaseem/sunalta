enum AlarmSound: String, CaseIterable, Identifiable {
    case morningLight = "white-alarm.wav"
    case quietOrbit = "midnight-alarm.wav"
    case meadowMorning = "grass-alarm.wav"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morningLight: "Morning Light"
        case .quietOrbit: "Quiet Orbit"
        case .meadowMorning: "Meadow Morning"
        }
    }
}
