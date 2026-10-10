import SwiftUI

struct ClockWeekdayGlowSettings: Codable, Equatable {
    var color = Color.Resolved(red: 1, green: 0.08, blue: 0.16)
    var halo = 0.25
    var brightness = 3000.0
    var spread = 60.0
    var direction = 0.0
    var reach = 5.0
}
