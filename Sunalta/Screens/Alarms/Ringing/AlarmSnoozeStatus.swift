import SwiftUI

struct AlarmSnoozeStatus: View {
    @Environment(\.appTheme) private var theme
    let until: Date

    var body: some View {
        Text(timerInterval: Date.distantPast...until, countsDown: true, showsHours: false)
            .font(.headline)
            .monospacedDigit()
            .contentTransition(.numericText(countsDown: true))
            .foregroundStyle(theme.palette.control)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel("Snooze time remaining")
            .accessibilityValue(Text(timerInterval: Date.distantPast...until, countsDown: true, showsHours: false))
            .accessibilityIdentifier("alarm-snooze-status")
    }
}
