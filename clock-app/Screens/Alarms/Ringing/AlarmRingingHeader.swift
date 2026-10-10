import SwiftUI

struct AlarmRingingHeader: View {
    @Environment(\.appTheme) private var theme
    let alarm: AlarmRecord
    // Preserve the display typography while following the user's Dynamic Type size.
    @ScaledMetric(relativeTo: .largeTitle) private var timeFontSize = 84

    var body: some View {
        VStack {
            Text("ALARM")
                .font(.caption.weight(.semibold))
                .tracking(3)
                .foregroundStyle(theme.palette.secondaryForeground)
            Text(AlarmTimeText.text(hour: alarm.hour, minute: alarm.minute))
                .font(.system(size: timeFontSize, weight: .light, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(alarm.label.isEmpty ? "Time to get up" : alarm.label)
                .font(.title2.weight(.medium))
                .multilineTextAlignment(.center)
        }
    }
}
