import SwiftUI

struct SupportStoryView: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Thank you for being here ♥")
                .bold()
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 16) {
                Text("Sunalta started as a small attempt to make focus feel easier and more intentional. Every person who uses it, shares it, reviews it, or supports it helps keep that idea alive.")
                Text("If this has helped you, consider leaving a review, telling a friend, or making a small donation.")
            }
        }
        .font(.callout)
        .foregroundStyle(theme.palette.secondaryForeground)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}
