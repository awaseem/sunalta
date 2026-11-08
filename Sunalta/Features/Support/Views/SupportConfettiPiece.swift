import SwiftUI

struct SupportConfettiPiece {
    let position = Double.random(in: 0...1)
    let delay = Double.random(in: 0...1.2)
    let duration = Double.random(in: 2.5...3.6)
    let sway = Double.random(in: 1.5...4)
    let spin = Double.random(in: -240...240)
    let isRound = Bool.random()
    let color = [Color.pink, .yellow, .mint, .cyan, .purple, .orange].randomElement() ?? .pink
}
