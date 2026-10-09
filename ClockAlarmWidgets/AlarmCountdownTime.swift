import AlarmKit
import AppIntents
import SwiftUI

struct AlarmCountdownTime: View {
    let mode: AlarmPresentationState.Mode

    var body: some View {
        switch mode {
        case .countdown(let countdown):
            Text(timerInterval: countdown.startDate...countdown.fireDate, countsDown: true)
                .monospacedDigit()
                .accessibilityLabel("Time until the alarm rings")
        case .paused(let paused):
            let remaining = Int(max(0, paused.totalCountdownDuration - paused.previouslyElapsedDuration))
            Text(Duration.seconds(remaining), format: .time(pattern: .minuteSecond)).monospacedDigit()
        case .alert:
            Text("Ringing")
        @unknown default:
            Text("Alarm")
        }
    }
}
