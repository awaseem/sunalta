import SwiftUI

struct ClockSupportButton: View {
    @State private var showsSupport = false

    var body: some View {
        Button {
            showsSupport = true
        } label: {
            SupportLabel(heartSize: 18)
                .labelStyle(.iconOnly)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Support")
        .accessibilityHint("Support the development of Clock App with an optional tip")
        .sheet(isPresented: $showsSupport) {
            ClockSupportSheet()
        }
    }
}
