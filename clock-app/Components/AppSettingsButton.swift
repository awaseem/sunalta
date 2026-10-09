import SwiftUI
import UIKit

/// UIKit supplies the supported URL for opening this app's Settings page.
struct AppSettingsButton: View {
    @Environment(\.openURL) private var openURL
    var title = "Open Settings"
    var onOpen: () -> Void = {}

    var body: some View {
        Button(title, action: openSettings)
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
        onOpen()
    }
}
