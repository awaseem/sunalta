import Foundation

enum AlarmEditorDestination: Identifiable {
    case create
    case edit(AlarmRecord)

    var id: String {
        switch self {
        case .create: "create"
        case .edit(let alarm): alarm.id.uuidString
        }
    }

    var alarm: AlarmRecord? {
        if case .edit(let alarm) = self { alarm } else { nil }
    }
}
