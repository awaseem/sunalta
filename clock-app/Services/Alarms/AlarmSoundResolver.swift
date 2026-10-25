import ActivityKit
import Foundation

/// Shared by previews and every AlarmKit schedule, including snoozes and scan reminders.
struct AlarmSoundResolver {
    var resourceURL: (String) -> URL? = { Bundle.main.url(forResource: $0, withExtension: nil) }

    func fileName(for selection: AlarmSoundSelection) -> String? {
        let fileName: String?
        switch selection {
        case .systemDefault:
            fileName = nil
        case .theme(let id):
            fileName = AppTheme.available.first { $0.id == id }?.audio.alarm?.rawValue
        case .named(let name):
            fileName = name
        }
        guard let fileName, resourceURL(fileName) != nil else { return nil }
        return fileName
    }

    func url(for selection: AlarmSoundSelection) -> URL? {
        fileName(for: selection).flatMap(resourceURL)
    }

    func alertSound(for selection: AlarmSoundSelection) -> AlertConfiguration.AlertSound {
        fileName(for: selection).map { .named($0) } ?? .default
    }
}
