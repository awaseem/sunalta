import SwiftUI

struct SupportStoryView: View {
    @Environment(\.appTheme) private var theme
    @ScaledMetric(relativeTo: .body) private var portraitSize = 140
    @ScaledMetric(relativeTo: .callout) private var paragraphSpacing = 20

    var body: some View {
        VStack(alignment: .leading, spacing: paragraphSpacing) {
            Image(.thankYouStamp)
                .resizable()
                .scaledToFit()
                .frame(width: min(portraitSize, 200), height: min(portraitSize, 200))
                .rotationEffect(.degrees(8))
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .accessibilityLabel("Sunalta's developer with his cat")

            Text("Thank you for being here ♥")
                .bold()
                .foregroundStyle(theme.palette.foreground)
                .accessibilityAddTraits(.isHeader)

            Text("I’m building Sunalta to make waking up a little easier. A review, a share, or a small tip helps me keep going.")

            Text("Tips are optional. Every feature is here for you either way.")
        }
        .font(.callout)
        .foregroundStyle(theme.palette.secondaryForeground)
        .fixedSize(horizontal: false, vertical: true)
    }
}
