import SwiftUI

struct AlarmRowContent: View {
    @Environment(\.appTheme) private var theme
    let hour: Int
    let minute: Int
    let name: String
    let repeatSummary: String
    let exitPointSummary: String
    let exitPointSymbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AlarmTimeLabel(hour: hour, minute: minute)
            if !name.isEmpty {
                Text(name)
                    .font(.headline)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            Text(repeatSummary)
                .font(.subheadline)
                .foregroundStyle(theme.palette.secondaryForeground)
            Label(exitPointSummary, systemImage: exitPointSymbol)
                .font(.caption)
                .foregroundStyle(theme.palette.secondaryForeground)
        }
    }
}
