import SwiftUI

/// A narrow highlight moves through the text's fill without adding a per-frame task.
struct ClockHintShimmer: ViewModifier {
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isActive: Bool
    let trigger: Int

    func body(content: Content) -> some View {
        let base = theme.palette.secondaryForeground
        let light = theme.colorScheme == .dark ? theme.palette.foreground : theme.palette.background

        if isActive && !reduceMotion {
            content.phaseAnimator([false, true], trigger: trigger) { content, swept in
                content.foregroundStyle(base)
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.2),
                                .init(color: light.opacity(0.55), location: 0.5),
                                .init(color: .clear, location: 0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .visualEffect { highlight, geometry in
                            highlight.offset(x: geometry.size.width * (swept ? 1 : -1))
                        }
                        .mask { content.foregroundStyle(.white) }
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    }
            } animation: { swept in
                swept ? .linear(duration: 2.2) : nil
            }
        } else {
            content.foregroundStyle(base)
        }
    }
}
