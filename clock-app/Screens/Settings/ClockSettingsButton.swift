import SwiftUI

struct ClockSettingsButton: View {
    @State private var showsSettings = false

    var body: some View {
        Button("Settings", systemImage: "gearshape") {
            showsSettings = true
        }
        .labelStyle(.iconOnly)
        .font(.subheadline)
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityHint("Choose a theme and manage clock sounds")
        .sheet(isPresented: $showsSettings) {
            ClockSettingsView()
        }
    }
}
