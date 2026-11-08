import SwiftUI

struct SupportConfettiView: View {
    let startDate: Date
    @State private var pieces = (0..<110).map { _ in SupportConfettiPiece() }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startDate)

                for piece in pieces {
                    let age = elapsed - piece.delay
                    let progress = age / piece.duration
                    guard progress >= 0, progress <= 1 else { continue }

                    let x = piece.position * size.width + sin(age * piece.sway) * 28
                    let y = -30 + (size.height + 60) * progress
                    var drawing = context
                    drawing.opacity = min(1, (1 - progress) * 6)
                    drawing.translateBy(x: x, y: y)
                    drawing.rotate(by: .degrees(age * piece.spin))
                    drawing.scaleBy(x: max(0.2, abs(cos(age * 4))), y: 1)
                    drawing.fill(
                        Path(
                            roundedRect: CGRect(x: -4, y: -6, width: 8, height: 12),
                            cornerRadius: piece.isRound ? 4 : 1
                        ),
                        with: .color(piece.color)
                    )
                }
            }
        }
        .clipped()
    }
}

#Preview {
    SupportConfettiView(startDate: Date())
        .allowsHitTesting(false)
}
