import SwiftData
import SwiftUI

/// Previews use an isolated store and runtime, never the app's persisted alarms.
struct AlarmPreviewContainer<Content: View>: View {
    private let container: Result<ModelContainer, Error>
    private let timeFormat: ClockTimeFormat
    private let content: () -> Content

    init(timeFormat: ClockTimeFormat = .twentyFourHour, @ViewBuilder content: @escaping () -> Content) {
        container = Result { try AlarmPreviewData.makeContainer() }
        self.content = content
        self.timeFormat = timeFormat
    }

    var body: some View {
        switch container {
        case .success(let container):
            AlarmPreviewEnvironment(container: container, timeFormat: timeFormat, content: content())
        case .failure(let error):
            ContentUnavailableView("Preview unavailable", systemImage: "exclamationmark.triangle",
                                   description: Text(error.localizedDescription))
        }
    }
}
