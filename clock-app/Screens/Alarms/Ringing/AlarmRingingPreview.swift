import SwiftUI

struct AlarmRingingPreview: View {
    private let alarm: Result<AlarmRecord, Error>

    init(exitPoint: AlarmExitPoint) {
        alarm = Result { try AlarmRecord(hour: 7, minute: 0, label: "Morning", exitPoint: exitPoint) }
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
