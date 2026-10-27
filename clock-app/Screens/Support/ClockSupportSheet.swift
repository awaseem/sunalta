import SwiftUI

struct ClockSupportSheet: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ClockSupportView()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Close support", systemImage: "xmark") { dismiss() }
                            .labelStyle(.iconOnly)
                    }
                }
        }
        .appTheme(theme)
        .presentationBackground(theme.palette.background)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationSizing(.form)
    }
}
