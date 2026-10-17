import SwiftUI
import UIKit

struct SculptedClockView: UIViewRepresentable {
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ClockAudioService.self) private var audioService: ClockAudioService?
    let date: Date
    var scene: ClockScene = .numbers
    var isScrolling = false
    var isVisible = true
    var isEditingAppearance = false
    var contentSafeAreaInsets: UIEdgeInsets = .zero
    var weekdayFrame: CGRect = .zero
    var onWeekdayAnchorChange: ((CGPoint) -> Void)?
    var onContentRevealed: (() -> Void)?

    func makeUIView(context: Context) -> ClockPageView {
        ClockPageView(theme: theme, scene: scene, audioService: audioService)
    }

    func updateUIView(_ view: ClockPageView, context: Context) {
        view.onContentRevealed = {
            Task { @MainActor in onContentRevealed?() }
        }
        view.onWeekdayAnchorChange = { anchor in
            Task { @MainActor in
                onWeekdayAnchorChange?(anchor)
            }
        }
        view.update(date: date, theme: theme, insets: contentSafeAreaInsets,
                    isScrolling: isScrolling, isVisible: isVisible,
                    isEditingAppearance: isEditingAppearance, weekdayFrame: weekdayFrame,
                    allowsFlybys: !reduceMotion)
    }

    static func dismantleUIView(_ view: ClockPageView, coordinator: ()) {
        view.stop()
    }
}
