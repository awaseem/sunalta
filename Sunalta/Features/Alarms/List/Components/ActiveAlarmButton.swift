import SwiftUI

struct ActiveAlarmButton: View {
    @Environment(AlarmRuntime.self) private var runtime
    @Environment(\.appTheme) private var theme

    var body: some View {
        Button("Active alarm", action: runtime.presentActiveAlarm)
            .buttonStyle(.borderedProminent)
            .tint(theme.palette.control)
            .foregroundStyle(theme.palette.onControl)
            .accessibilityHint("Opens the active alarm")
            .accessibilityIdentifier("active-alarm-island")
    }
}
