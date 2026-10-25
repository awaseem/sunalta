import Foundation

struct AlarmEditorDraft {
    var time = Calendar.autoupdatingCurrent.date(
        from: DateComponents(year: 2001, month: 1, day: 1, hour: 7, minute: 0)
    ) ?? .now
    var repeatDays: Set<ClockWeekday> = []
    var snoozeEnabled = true
    var snoozeMinutes = 10
    var exitPoint = AlarmExitPointDraft()
    var name = ""
    var soundSelection: AlarmSoundSelection = .theme(AppTheme.defaultTheme.id)

    func validate(calendar: Calendar = .autoupdatingCurrent) throws {
        let components = timeComponents(calendar: calendar)
        guard let hour = components.hour, let minute = components.minute,
              (0...23).contains(hour), (0...59).contains(minute) else {
            throw AlarmValidationError.invalidTime
        }
        guard snoozeMinutes > 0 else { throw AlarmValidationError.invalidSnoozeDuration }
        if let code = exitPoint.scannedCode {
            guard code.kind == exitPoint.selection.scanKind,
                  AlarmStopTarget.isValidScan(codeValue: code.value, kind: code.kind) else {
                throw AlarmValidationError.invalidScanTarget
            }
        }
    }

    func timeComponents(calendar: Calendar = .autoupdatingCurrent) -> DateComponents {
        calendar.dateComponents([.hour, .minute], from: time)
    }

    var displayTime: String {
        let components = timeComponents()
        return AlarmTimeText.text(hour: components.hour ?? 7, minute: components.minute ?? 0)
    }
}

extension AlarmEditorDraft {
    init(theme: AppTheme) {
        self.init()
        soundSelection = .theme(theme.id)
    }

    init(alarm: AlarmRecord, theme: AppTheme = .defaultTheme, calendar: Calendar = .autoupdatingCurrent) {
        self.init(theme: theme)
        time = calendar.date(from: DateComponents(year: 2001, month: 1, day: 1,
                                                  hour: alarm.hour, minute: alarm.minute)) ?? time
        repeatDays = alarm.repeatDays
        snoozeEnabled = alarm.snoozeEnabled
        snoozeMinutes = alarm.snoozeDurationMinutes
        name = alarm.label
        soundSelection = alarm.soundSelection
        exitPoint.selection = alarm.exitPoint
        if let target = alarm.stopTargets.first, let kind = target.kind {
            exitPoint.scannedCode = .init(kind: kind, value: target.codeValue)
        }
    }
}
