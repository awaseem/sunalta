import SwiftUI

/// Matches Foqos's staggered spring entrance while respecting Reduce Motion.
struct SupportEntranceAnimation: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible || reduceMotion ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : 30)
            .onAppear {
                withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6).delay(delay)) {
                    isVisible = true
                }
            }
    }
}
