import SwiftUI

/// Full-screen wave rings, drawn separately so only this canvas updates each frame.
struct AlarmRingingRipples: View {
    @Environment(\.appTheme) private var theme
    let origin: CGPoint
    let pulses: [Date]
    let isActive: Bool
    @State private var frame = CGRect.zero
    private let duration: TimeInterval = 1.9

    var body: some View {
        TimelineView(.animation(paused: !isActive || pulses.isEmpty)) { timeline in
            Canvas { context, size in
                guard isActive else { return }
                let center = CGPoint(x: origin.x - frame.minX, y: origin.y - frame.minY)
                let farthestX = max(center.x, size.width - center.x)
                let farthestY = max(center.y, size.height - center.y)
                let maximumRadius = hypot(farthestX, farthestY)
                for pulse in pulses {
                    let age = timeline.date.timeIntervalSince(pulse)
                    guard age >= 0, age < duration else { continue }
                    let progress = age / duration
                    let radius = 28 + (maximumRadius - 28) * pow(progress, 0.8)
                    let opacity = 0.18 * min(progress / 0.08, 1) * pow(1 - progress, 1.1)
                    let ring = Path(ellipseIn: CGRect(
                        x: center.x - radius, y: center.y - radius,
                        width: radius * 2, height: radius * 2
                    ))
                    var halo = context
                    halo.addFilter(.blur(radius: 4))
                    halo.stroke(ring, with: .color(theme.palette.foreground.opacity(opacity * 0.35)), lineWidth: 9)
                    context.stroke(ring, with: .color(theme.palette.foreground.opacity(opacity)), lineWidth: 1.5)
                }
            }
        }
        .onGeometryChange(for: CGRect.self) { geometry in
            geometry.frame(in: .named("alarmRingingScreen"))
        } action: { frame = $0 }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
