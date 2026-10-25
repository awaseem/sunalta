import SwiftUI

struct SettingsSoundLabel: View {
    @Environment(\.appTheme) private var theme
    @ScaledMetric(relativeTo: .body) private var iconWidth = 24
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let systemImage: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(theme.palette.foreground)
                .frame(width: iconWidth)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.body)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(theme.palette.secondaryForeground)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
