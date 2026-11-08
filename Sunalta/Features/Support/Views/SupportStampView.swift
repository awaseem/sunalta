import SwiftUI

struct SupportStampView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var portraitSize = 140
    @State private var isVisible = false

    var body: some View {
        Image(.thankYouStamp)
            .resizable()
            .scaledToFit()
            .frame(width: min(portraitSize, 200), height: min(portraitSize, 200))
            .frame(maxWidth: .infinity)
            .scaleEffect(isVisible || reduceMotion ? 1 : 0.1)
            .rotationEffect(.degrees(isVisible || reduceMotion ? 8 : 0))
            .opacity(isVisible || reduceMotion ? 1 : 0)
            .accessibilityLabel("Sunalta's developer with his cat")
            .onAppear {
                withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6)) {
                    isVisible = true
                }
            }
    }
}
