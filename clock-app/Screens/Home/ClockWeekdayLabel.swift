import SwiftUI

struct ClockWeekdayLabel: View {
    @Environment(\.appTheme) private var theme
    @ScaledMetric(relativeTo: .title2) private var textScale: CGFloat = 1
    let date: Date

    var body: some View {
        if let weekday = ClockWeekday(rawValue: Calendar.autoupdatingCurrent.component(.weekday, from: date)) {
            Text(weekday.abbreviation)
                .font(.system(size: CGFloat(theme.weekday.size) * textScale,
                              weight: theme.weekday.weight.fontWeight))
                .foregroundStyle(Color(theme.weekday.glow.color))
                .shadow(color: Color(theme.weekday.glow.color).opacity(theme.weekday.glow.halo),
                        radius: 3 * textScale)
                .shadow(color: Color(theme.weekday.glow.color).opacity(theme.weekday.glow.halo * 0.5),
                        radius: 10 * textScale)
                .accessibilityLabel(weekday.name)
                .allowsHitTesting(false)
        }
    }
}
