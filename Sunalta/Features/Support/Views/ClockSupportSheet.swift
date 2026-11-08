import SwiftUI

struct ClockSupportSheet: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        ClockSupportView()
            .appTheme(theme)
            .presentationBackground(theme.palette.background)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationSizing(.form)
    }
}
