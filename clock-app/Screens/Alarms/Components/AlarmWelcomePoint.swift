import SwiftUI

struct AlarmWelcomePoint: View {
    @Environment(\.appTheme) private var theme
    @ScaledMetric(relativeTo: .title2) private var iconWidth = 28
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let systemImage: String

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: systemImage)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(theme.palette.selection)
                .frame(width: iconWidth, alignment: .leading)
                .accessibilityHidden(true)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(theme.palette.foreground)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(theme.palette.secondaryForeground)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
        .accessibilityElement(children: .combine)
    }
}
