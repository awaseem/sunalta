import Foundation

enum AlarmValidationError: Error, Equatable {
    case invalidTime
    case invalidSnoozeDuration
    case invalidSoundName
    case invalidScanTarget
}
