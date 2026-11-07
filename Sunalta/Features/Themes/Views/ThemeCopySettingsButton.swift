import SwiftUI
import UIKit

struct ThemeCopySettingsButton: View {
    @Environment(ThemeSettings.self) private var settings
    @Environment(\.self) private var environment
    @State private var copied = false
    @State private var copyFailed = false

    var body: some View {
        Button(copied ? "Settings copied" : "Copy settings",
               systemImage: copied ? "checkmark" : "doc.on.doc") {
            do {
                UIPasteboard.general.string = try settings.exportText(in: environment)
                copied = true
            } catch {
                copyFailed = true
            }
        }
        .labelStyle(.iconOnly)
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityHint("Copies all current theme values so you can paste them into a message")
        .task(id: copied) {
            guard copied else { return }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            copied = false
        }
        .alert("Couldn't copy settings", isPresented: $copyFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please try again.")
        }
    }
}
