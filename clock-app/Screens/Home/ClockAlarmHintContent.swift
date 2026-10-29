import SwiftUI

struct ClockAlarmHintContent: View {
    @Environment(ClockDisplaySettings.self) private var settings
    @Environment(\.locale) private var locale
    @Environment(\.appTheme) private var theme
    @Environment(\.calendar) private var calendar
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var showsSwipeHint = false
    @State private var arrowBounce = 0
    @State private var shimmerTrigger = 0

    let nextAlarm: Date?
    let now: Date
    let isActive: Bool

    var body: some View {
        let shouldRotate = isActive && !voiceOverEnabled && nextAlarm != nil
        let shouldShimmer = isActive && !voiceOverEnabled && !reduceMotion

        ZStack {
            if nextAlarm == nil || showsSwipeHint {
                VStack(spacing: 4) {
                    Text("Swipe up for alarms")
                        .font(.subheadline)
                        .modifier(ClockHintShimmer(isActive: isActive, trigger: shimmerTrigger))
                    Image(systemName: "chevron.up")
                        .font(.caption.bold())
                        .symbolEffect(.bounce.up, options: .nonRepeating.speed(0.9), value: arrowBounce)
                        .accessibilityHidden(true)
                }
                .transition(reduceMotion ? .opacity : .push(from: .bottom))
            } else if let nextAlarm {
                Text(alarmDescription(for: nextAlarm))
                    .font(.subheadline)
                    .monospacedDigit()
                    .modifier(ClockHintShimmer(isActive: isActive, trigger: shimmerTrigger))
                    .transition(reduceMotion ? .opacity : .push(from: .bottom))
            }
        }
        .foregroundStyle(theme.palette.secondaryForeground)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(nextAlarm.map { "Next alarm, \(alarmDescription(for: $0))" } ?? "Swipe up for alarms")
        .accessibilityHint("Alarms are on the page below.")
        .task(id: shouldRotate) {
            showsSwipeHint = false
            guard shouldRotate else { return }
            do {
                while !Task.isCancelled {
                    try await Task.sleep(for: .seconds(3))
                    withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.45, bounce: 0.12)) {
                        showsSwipeHint.toggle()
                    }
                    try await Task.sleep(for: .milliseconds(450))
                    if showsSwipeHint && !reduceMotion {
                        arrowBounce += 1
                    }
                }
            } catch is CancellationError {
                // Stop rotating when the clock is offscreen or the app is inactive.
            } catch {
                return
            }
        }
        .task(id: shouldShimmer) {
            guard shouldShimmer else { return }
            do {
                while !Task.isCancelled {
                    try await Task.sleep(for: .seconds(8))
                    shimmerTrigger += 1
                }
            } catch {
                // Cancellation keeps the offscreen hint idle.
                return
            }
        }
    }

    private func alarmDescription(for nextAlarm: Date) -> String {
        let time = ClockTimeDisplay(date: nextAlarm, format: settings.format,
                                    calendar: calendar, locale: locale).text
        if calendar.isDate(nextAlarm, inSameDayAs: now) {
            return "Today · \(time)"
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(nextAlarm, inSameDayAs: tomorrow) {
            return "Tomorrow · \(time)"
        }
        return "\(nextAlarm.formatted(.dateTime.weekday(.wide))) · \(time)"
    }
}

#Preview("Upcoming alarm") {
    @Previewable @State var settings = ClockDisplaySettings(defaults: PreviewDefaults.make())
    ClockAlarmHintContent(nextAlarm: .now.addingTimeInterval(8 * 60 * 60), now: .now, isActive: true)
        .padding()
        .environment(settings)
}

#Preview("No alarms") {
    @Previewable @State var settings = ClockDisplaySettings(defaults: PreviewDefaults.make())
    ClockAlarmHintContent(nextAlarm: nil, now: .now, isActive: true)
        .padding()
        .environment(settings)
}
