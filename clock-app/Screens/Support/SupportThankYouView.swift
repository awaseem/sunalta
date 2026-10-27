import SwiftUI

struct SupportThankYouView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .largeTitle) private var heartSize = 88

    var body: some View {
        ScrollView {
            VStack {
                Image(.supportStickerLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(heartSize, 180), height: min(heartSize, 180))
                    .accessibilityHidden(true)
                Text("Thank you so much!")
                    .font(.title2.bold())
                    .padding(.top)
                    .accessibilityAddTraits(.isHeader)
                Text("Your support means a lot and helps keep Clock App going.")
                    .foregroundStyle(theme.palette.secondaryForeground)
                    .padding(.top)
                Button("Done") { dismiss() }
                    .buttonStyle(.appCapsule)
                    .padding(.top)
            }
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .defaultScrollAnchor(.center, for: .alignment)
    }
}
