import SwiftUI

/// A flat label positioned at the resting projection of the right hour digit.
struct ClockPeriodLabel: View {
    @Environment(\.appTheme) private var theme
    @State private var size: CGSize = .zero
    let period: String
    let anchor: CGPoint
    let availableWidth: CGFloat

    var body: some View {
        Text(period)
            .font(.system(.title3, weight: theme.weekday.weight.fontWeight))
            .foregroundStyle(theme.palette.clockPeriod)
            .fixedSize()
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
            .offset(x: max(16, min(anchor.x + 12, availableWidth - size.width - 16)),
                    y: anchor.y - size.height - 4)
            .allowsHitTesting(false)
            // The complete clock accessibility label always includes the period.
            .accessibilityHidden(true)
    }
}
