import SwiftUI

struct AlarmRingingHeader: View {
    @Environment(\.appTheme) private var theme
    let alarm: AlarmRecord
    // Preserve the display typography while following the user's Dynamic Type size.
    @ScaledMetric(relativeTo: .largeTitle) private var timeFontSize = 84

    var body: some View {
        VStack {
            Text(AlarmTimeText.text(hour: alarm.hour, minute: alarm.minute))
                .font(.system(size: timeFontSize, design: .rounded))
                .bold()
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
            if !alarm.label.isEmpty {
                Text(alarm.label)
                    .font(.title2)
                    .foregroundStyle(theme.palette.secondaryForeground)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
