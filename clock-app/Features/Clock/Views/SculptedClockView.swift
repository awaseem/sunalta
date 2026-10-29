import SwiftUI
import UIKit

struct SculptedClockView: UIViewRepresentable {
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ClockAudioService.self) private var audioService: ClockAudioService?
    let display: ClockTimeDisplay
    var isScrolling = false
    var isVisible = true
    var isEditingAppearance = false
    var showsAlarmHint = true
    var contentSafeAreaInsets: UIEdgeInsets = .zero
    var weekdayFrame: CGRect = .zero
    var onWeekdayAnchorChange: ((CGPoint) -> Void)?
    var onPeriodAnchorChange: ((CGPoint) -> Void)?
    var onContentRevealed: (() -> Void)?

    func makeUIView(context: Context) -> ClockPageView {
        ClockPageView(theme: theme, audioService: audioService)
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
        view.onPeriodAnchorChange = { anchor in
            Task { @MainActor in onPeriodAnchorChange?(anchor) }
        }
        view.update(display: display, theme: theme, insets: contentSafeAreaInsets,
                    isScrolling: isScrolling, isVisible: isVisible,
                    isEditingAppearance: isEditingAppearance, weekdayFrame: weekdayFrame,
                    allowsFlybys: !reduceMotion, showsAlarmHint: showsAlarmHint)
    }

    static func dismantleUIView(_ view: ClockPageView, coordinator: ()) {
        view.stop()
    }
}
