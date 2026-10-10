import SwiftUI

struct AlarmEmptyState: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    @State private var isVisible = false
    var isScrolling = false
    let isPresentingAlarm: Bool
    let createAlarm: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            VStack {
                Text("Welcome")
                    .font(.largeTitle.bold())
                    .foregroundStyle(theme.palette.foreground)
                    .accessibilityAddTraits(.isHeader)
                Text("Set your first alarm and make mornings your own.")
                    .font(.body)
                    .foregroundStyle(theme.palette.secondaryForeground)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

            TimelineView(.everyMinute) { context in
                SculptedClockView(date: context.date, scene: .alarm,
                                  isScrolling: isScrolling,
                                  isVisible: isVisible && scenePhase == .active && !isPresentingAlarm)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 440)
            .onScrollVisibilityChange(threshold: 0.05) { isVisible = $0 }

            Button("Create alarm", action: createAlarm)
                .font(.headline)
                .frame(minHeight: 44)
                .padding(.horizontal, 24)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(theme.palette.control)
                .foregroundStyle(theme.palette.onControl)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
}

#Preview("No alarms") {
    ScrollView {
        AlarmEmptyState(isPresentingAlarm: false, createAlarm: {})
    }
    .appTheme(.white)
}
