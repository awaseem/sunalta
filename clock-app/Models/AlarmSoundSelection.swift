/// Uses the existing optional soundName column, preserving legacy filenames and nil defaults.
/// A theme choice captures its ID at creation; it never follows the current appearance setting.
nonisolated enum AlarmSoundSelection: Equatable, Hashable, Sendable {
    case systemDefault
    case theme(String)
    case named(String)

    init(storedValue: String?) {
        guard let storedValue else {
            self = .systemDefault
            return
        }
        if storedValue.hasPrefix("theme:") {
            self = .theme(String(storedValue.dropFirst("theme:".count)))
        } else {
            self = .named(storedValue)
        }
    }

    var storedValue: String? {
        switch self {
        case .systemDefault: nil
        case .theme(let id): "theme:\(id)"
        case .named(let fileName): fileName
        }
    }
}
