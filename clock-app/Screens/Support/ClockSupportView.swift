import StoreKit
import SwiftUI

struct ClockSupportView: View {
    @Environment(TipStore.self) private var tips
    @Environment(\.appTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .callout) private var sectionSpacing = 36
    @State private var hasConfirmedTip = false
    @State private var showsThankYou = false
    @AccessibilityFocusState private var thankYouFocused: Bool

    var body: some View {
        Group {
            if showsThankYou {
                SupportThankYouView()
                    .accessibilityFocused($thankYouFocused)
                    .transition(.opacity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: sectionSpacing) {
                        SupportStoryView()
                        SupportSocialLinks()
                        SupportTipSection()
                    }
                    .padding()
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .background(theme.palette.background)
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: tips.completedTipCount) {
            hasConfirmedTip = true
            showThanksIfActive()
        }
        .onChange(of: scenePhase) { showThanksIfActive() }
        .sensoryFeedback(.success, trigger: showsThankYou)
        .task {
            await tips.loadProducts()
            for await _ in Storefront.updates {
                guard !Task.isCancelled else { return }
                await tips.loadProducts()
            }
        }
    }

    private func showThanksIfActive() {
        guard hasConfirmedTip, scenePhase == .active else { return }
        withAnimation(reduceMotion ? nil : .easeInOut) {
            showsThankYou = true
        }
        thankYouFocused = true
    }
}

#Preview("White support") {
    ClockSupportSheet()
        .environment(TipStore())
        .appTheme(.white)
}

#Preview("Midnight support") {
    ClockSupportSheet()
        .environment(TipStore())
        .appTheme(.midnight)
}

#Preview("Grass support · large text") {
    ClockSupportSheet()
        .environment(TipStore())
        .appTheme(.grass)
        .environment(\.dynamicTypeSize, .accessibility3)
}
