import StoreKit
import SwiftUI

struct ClockSupportView: View {
    @Environment(TipStore.self) private var tips
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasPendingCelebration = false
    @State private var celebrationStart: Date?
    @State private var showsThankYou = false
    @AccessibilityFocusState private var thankYouFocused: Bool

    var body: some View {
        NavigationStack {
            SupportContentView()
                .opacity(showsThankYou ? 0 : 1)
                .allowsHitTesting(!showsThankYou)
                .accessibilityHidden(showsThankYou)
                .overlay {
                    if showsThankYou {
                        SupportThankYouView()
                            .id(celebrationStart)
                            .accessibilityFocused($thankYouFocused)
                            .transition(.opacity)
                    }
                }
                .background(theme.palette.background)
                .navigationTitle("Support")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close support", systemImage: "xmark") { dismiss() }
                            .labelStyle(.iconOnly)
                    }
                }
        }
        .overlay {
            if let celebrationStart, !reduceMotion {
                SupportConfettiView(startDate: celebrationStart)
                    .id(celebrationStart)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .onChange(of: tips.completedTipCount) {
            hasPendingCelebration = true
            showThanksIfActive()
        }
        .onChange(of: scenePhase) { showThanksIfActive() }
        .sensoryFeedback(.success, trigger: tips.completedTipCount)
        .task(id: celebrationStart) {
            guard celebrationStart != nil else { return }
            do {
                try await Task.sleep(for: .seconds(4))
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                    showsThankYou = false
                }
                thankYouFocused = false
                try await Task.sleep(for: .seconds(1))
                celebrationStart = nil
            } catch {
                return
            }
        }
        .task {
            await tips.loadProducts()
            for await _ in Storefront.updates {
                guard !Task.isCancelled else { return }
                await tips.loadProducts()
            }
        }
    }

    private func showThanksIfActive() {
        guard hasPendingCelebration, scenePhase == .active else { return }
        hasPendingCelebration = false
        celebrationStart = Date()
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
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
