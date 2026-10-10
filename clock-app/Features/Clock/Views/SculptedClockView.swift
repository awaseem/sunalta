import SwiftUI
import UIKit

struct SculptedClockView: UIViewRepresentable {
    @Environment(\.appTheme) private var theme
    let date: Date
    var scene: ClockScene = .numbers
    var isScrolling = false
    var isVisible = true
    var isEditingAppearance = false
    var contentSafeAreaInsets: UIEdgeInsets = .zero
    var weekdayFrame: CGRect = .zero
    var onWeekdayAnchorChange: ((CGPoint) -> Void)?

    func makeUIView(context: Context) -> ClockPageView {
        ClockPageView(theme: theme, scene: scene)
    }

    func updateUIView(_ view: ClockPageView, context: Context) {
        view.onWeekdayAnchorChange = { anchor in
            Task { @MainActor in
                onWeekdayAnchorChange?(anchor)
            }
        }
        view.update(date: date, theme: theme, insets: contentSafeAreaInsets,
                    isScrolling: isScrolling, isVisible: isVisible,
                    isEditingAppearance: isEditingAppearance, weekdayFrame: weekdayFrame)
    }

    static func dismantleUIView(_ view: ClockPageView, coordinator: ()) {
        view.stop()
    }
}
