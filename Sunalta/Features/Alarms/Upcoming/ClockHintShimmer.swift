import SwiftUI

/// A narrow highlight moves through the text's fill without adding a per-frame task.
struct ClockHintShimmer: ViewModifier {
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isActive: Bool
    let isVisible: Bool

    func body(content: Content) -> some View {
        let base = theme.palette.secondaryForeground
        let light = theme.colorScheme == .dark ? theme.palette.foreground : theme.palette.background

        content.foregroundStyle(base)
            .overlay {
                if isActive && !reduceMotion {
                    // Animate only the highlight so shimmer timing cannot retime the text's entrance.
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.2),
                            .init(color: light.opacity(0.55), location: 0.5),
                            .init(color: .clear, location: 0.8),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .phaseAnimator([false, true], trigger: isVisible) { highlight, swept in
                        highlight.visualEffect { effect, geometry in
                            effect.offset(x: geometry.size.width * (swept ? 1 : -1))
                        }
                    } animation: { swept in
                        swept && isVisible ? .linear(duration: 0.65) : nil
                    }
                    .mask { content.foregroundStyle(.white) }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
    }
}
