import SwiftUI

struct AlarmRingingPreview: View {
    private let alarm: Result<AlarmRecord, Error>

    init(exitPoint: AlarmExitPoint, snoozeEnabled: Bool = true, snoozed: Bool = false) {
        alarm = Result {
            let alarm = try AlarmRecord(hour: 7, minute: 0, label: "Morning",
                                        snoozeEnabled: snoozeEnabled, exitPoint: exitPoint)
            if snoozed { alarm.snoozedUntil = .now.addingTimeInterval(9 * 60) }
            return alarm
        }
    }

    var body: some View {
        AlarmPreviewContainer {
            switch alarm {
            case .success(let alarm): AlarmRingingScreen(alarm: alarm)
            case .failure(let error): Text(error.localizedDescription)
            }
        }
    }
}
