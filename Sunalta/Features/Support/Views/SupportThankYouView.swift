import SwiftUI

struct SupportThankYouView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var heartSize = 88
    @State private var isPulsing = false
    @State private var isTextVisible = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(heartSize, 180), height: min(heartSize, 180))
                    .foregroundStyle(.pink)
                    .scaleEffect(isPulsing && !reduceMotion ? 1.12 : 1)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 0.55).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
                    .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text("Thank you so much!")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text("Your support means a lot and helps keep Sunalta going.")
                        .font(.body)
                        .foregroundStyle(theme.palette.secondaryForeground)
                }
                .opacity(isTextVisible || reduceMotion ? 1 : 0)
                .offset(y: isTextVisible || reduceMotion ? 0 : 20)
                .animation(
                    reduceMotion ? nil : .easeOut(duration: 0.5).delay(0.15),
                    value: isTextVisible
                )
            }
            .multilineTextAlignment(.center)
            .padding(32)
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
        .scrollBounceBehavior(.basedOnSize)
        .defaultScrollAnchor(.center, for: .alignment)
        .onAppear {
            isPulsing = true
            isTextVisible = true
        }
    }
}

#Preview("Thank you") {
    SupportThankYouView()
        .appTheme(.white)
}

#Preview("Thank you · midnight") {
    SupportThankYouView()
        .appTheme(.midnight)
}
