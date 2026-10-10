import Foundation

/// Clockwise angles from twelve at minute precision, matching the display cadence.
struct AnalogClockTime {
    let hourAngle: Float
    let minuteAngle: Float

    init(date: Date, calendar: Calendar = .autoupdatingCurrent) {
        let time = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = Double(time.minute ?? 0)
        let hours = Double((time.hour ?? 0) % 12) + minutes / 60
        hourAngle = Float(hours / 12 * 2 * .pi)
        minuteAngle = Float(minutes / 60 * 2 * .pi)
    }
}
