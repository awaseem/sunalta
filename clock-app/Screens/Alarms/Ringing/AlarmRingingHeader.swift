import SwiftUI

struct AlarmRingingHeader: View {
    let alarm: AlarmRecord
    // Preserve the display typography while following the user's Dynamic Type size.
    @ScaledMetric(relativeTo: .largeTitle) private var timeFontSize = 84

    var body: some View {
        Text(AlarmTimeText.text(hour: alarm.hour, minute: alarm.minute))
            .font(.system(size: timeFontSize, design: .rounded))
            .bold()
            .monospacedDigit()
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .accessibilityAddTraits(.isHeader)
    }
}
