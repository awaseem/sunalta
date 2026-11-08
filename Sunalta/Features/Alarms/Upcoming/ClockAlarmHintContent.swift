import SwiftUI

struct ClockAlarmHintContent: View {
    private static let fadeDuration = 0.1
    private static let transitionDuration = 0.12
    private static let transitionDistance: CGFloat = 12

    @Environment(ClockDisplaySettings.self) private var settings
    @Environment(\.locale) private var locale
    @Environment(\.appTheme) private var theme
    @Environment(\.calendar) private var calendar
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var phase = ClockAlarmHintPhase.hidden

    let nextAlarm: Date?
    let now: Date
    let isActive: Bool

    var body: some View {
        let shouldShimmer = isActive && !voiceOverEnabled

        ZStack {
            // Keep both messages mounted so every reveal can trigger a fresh shimmer.
            VStack(spacing: 4) {
                Text("Swipe up for alarms")
                    .font(.subheadline)
                    .modifier(ClockHintShimmer(isActive: shouldShimmer, isVisible: phase == .swipe))
                Image(systemName: "chevron.up")
                    .font(.caption.bold())
                    .accessibilityHidden(true)
            }
            .opacity(phase == .swipe ? 1 : 0)
            .animation(
                phase == .swipe
                    ? .easeIn(duration: Self.transitionDuration)
                    : .easeOut(duration: Self.fadeDuration),
                value: phase == .swipe
            )
            .offset(
                y: reduceMotion || phase == .swipe
                    ? 0
                    : (phase == .swipeExiting ? -Self.transitionDistance : Self.transitionDistance)
            )

            if let nextAlarm {
                Text(alarmDescription(for: nextAlarm))
                    .font(.subheadline)
                    .monospacedDigit()
                    .modifier(
                        ClockHintShimmer(isActive: shouldShimmer, isVisible: phase == .nextAlarm)
                    )
                    .opacity(phase == .nextAlarm ? 1 : 0)
                    .animation(
                        phase == .nextAlarm
                            ? .easeIn(duration: Self.transitionDuration)
                            : .easeOut(duration: Self.fadeDuration),
                        value: phase == .nextAlarm
                    )
                    .offset(
                        y: reduceMotion || phase == .nextAlarm
                            ? 0
                            : (phase == .nextAlarmExiting
                                ? -Self.transitionDistance : Self.transitionDistance)
                    )
            }
        }
        .foregroundStyle(theme.palette.secondaryForeground)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            nextAlarm.map { "Next alarm, \(alarmDescription(for: $0))" } ?? "Swipe up for alarms"
        )
        .accessibilityHint("Alarms are on the page below.")
        .task(id: [isActive, voiceOverEnabled, reduceMotion, nextAlarm != nil]) {
            phase = .hidden
            guard isActive else { return }
            guard !voiceOverEnabled else {
                phase = nextAlarm == nil ? .swipe : .nextAlarm
                return
            }
            do {
                while !Task.isCancelled {
                    try await Task.sleep(for: .seconds(2))
                    try await show(.swipe, exitingTo: .swipeExiting)

                    guard nextAlarm != nil else { continue }
                    try await Task.sleep(for: .seconds(2))
                    try await show(.nextAlarm, exitingTo: .nextAlarmExiting)
                }
            } catch {
                // Stop the sequence when the clock is offscreen or the app is inactive.
            }
        }
    }

    private func show(_ visiblePhase: ClockAlarmHintPhase, exitingTo exitPhase: ClockAlarmHintPhase)
        async throws
    {
        withAnimation(.easeIn(duration: Self.transitionDuration)) {
            phase = visiblePhase
        }
        // Hold for two full seconds after the entrance animation finishes.
        try await Task.sleep(for: .seconds(Self.transitionDuration + 2))
        withAnimation(.easeIn(duration: Self.transitionDuration)) {
            phase = exitPhase
        }
        try await Task.sleep(for: .seconds(Self.transitionDuration))
        phase = .hidden
    }

    private func alarmDescription(for nextAlarm: Date) -> String {
        let time = ClockTimeDisplay(
            date: nextAlarm, format: settings.format,
            calendar: calendar, locale: locale
        ).text
        if calendar.isDate(nextAlarm, inSameDayAs: now) {
            return "Today · \(time)"
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
            calendar.isDate(nextAlarm, inSameDayAs: tomorrow)
        {
            return "Tomorrow · \(time)"
        }
        return "\(nextAlarm.formatted(.dateTime.weekday(.wide))) · \(time)"
    }
}

#Preview("Upcoming alarm") {
    @Previewable @State var settings = ClockDisplaySettings(defaults: PreviewDefaults.make())
    ClockAlarmHintContent(
        nextAlarm: .now.addingTimeInterval(8 * 60 * 60), now: .now, isActive: true
    )
    .padding()
    .environment(settings)
}

#Preview("No alarms") {
    @Previewable @State var settings = ClockDisplaySettings(defaults: PreviewDefaults.make())
    ClockAlarmHintContent(nextAlarm: nil, now: .now, isActive: true)
        .padding()
        .environment(settings)
}
