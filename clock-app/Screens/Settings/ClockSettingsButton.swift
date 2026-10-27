import SwiftUI

struct ClockSettingsButton: View {
    @State private var showsSettings = false

    var body: some View {
        Button {
            showsSettings = true
        } label: {
            Label("Settings", systemImage: "gearshape")
                .labelStyle(.iconOnly)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Choose a theme and manage clock sounds")
        .sheet(isPresented: $showsSettings) {
            ClockSettingsView()
        }
    }
}
