import SwiftData
import SwiftUI

struct AlarmPreviewEnvironment<Content: View>: View {
    private let container: ModelContainer
    private let content: Content
    @State private var runtime: AlarmRuntime
    @State private var themeSettings = ThemeSettings(
        defaults: UserDefaults(suiteName: "AlarmThemePreview") ?? .standard
    )

    init(container: ModelContainer, content: Content) {
        self.container = container
        self.content = content
        _runtime = State(initialValue: AlarmRuntime(context: container.mainContext))
    }

    var body: some View {
        content
            .modelContainer(container)
            .environment(runtime)
            .environment(themeSettings)
            .appTheme(themeSettings.theme)
    }
}
