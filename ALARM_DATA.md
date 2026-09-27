# Alarm data

The app's scene installs an on-disk SwiftData container for `AlarmRecord` and `AlarmStopTarget`. Views can use `@Query` and the environment's `modelContext`.

```swift
let target = try AlarmStopTarget(name: "Bathroom", kind: .qrCode, codeValue: "my-wake-up-code")
let alarm = try AlarmRecord(
    hour: 7, minute: 30, label: "Wake up",
    repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
    requiresScanToStop: true, stopTargets: [target]
)
modelContext.insert(alarm)
try modelContext.save()
let schedule = try alarm.alarmKitSchedule()
```

- Time is stored as 24-hour hour/minute values in the device's local timezone. Empty repeat days mean the next occurrence only; all seven days mean daily.
- `id` is the stable UUID to pass to AlarmManager. `isEnabled` stores user intent, not proof that an alarm has been scheduled or authorized.
- `soundName == nil` means the default sound. A custom value must identify an actual app bundle or Library/Sounds file. Apple Clock sound names in the reference screenshot are not bundled here.
- Snooze defaults to enabled with a nine-minute duration. The model retains the duration when snooze is disabled.
- Ordinary alarms default to `requiresScanToStop == false`. Scan-required alarms must have at least one target; any matching configured target is accepted.
- Targets can be shared. Deleting an alarm preserves its targets. Deleting a target removes its relationships but preserves each alarm's scan requirement. The editor/scheduler must call `validate()` before saving changes or scheduling; an alarm missing its last required target must be repaired or disabled.
- Targets follow Foqos: `codeValue` holds the uppercase hex NFC identifier (use `AlarmStopTarget.nfcIdentifier(from:)`) or CodeScanner’s `ScanResult.string`. Both QR codes and barcodes use `.qrCode`; symbology is not stored or matched. Values are trimmed. For URLs, scheme and host are lowercased and a bare root slash is removed. Other text retains case and leading zeros. Pass the scanned string and kind to `acceptsScan(codeValue:kind:)`. Scan matching is a convenience check, not cryptographic authentication.

This adds persistence and schedule conversion only. It does not yet register alarms with AlarmManager, request authorization, capture camera/NFC scans, implement stop intents, or enforce scan-to-stop in the system alarm presentation. SwiftData deletion alone does not cancel an already scheduled system alarm; the future scheduling service must coordinate both stores.

Schedule conversion follows [Apple's AlarmKit sample](https://developer.apple.com/documentation/alarmkit/scheduling-an-alarm-with-alarmkit).
