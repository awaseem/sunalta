import SwiftUI
import UIKit

struct SculptedClockView: UIViewRepresentable {
    @Environment(\.appTheme) private var theme
    let date: Date
    var isScrolling = false
    var isVisible = true
    var isEditingAppearance = false
    var contentSafeAreaInsets: UIEdgeInsets = .zero

    func makeUIView(context: Context) -> ClockPageView {
        ClockPageView(theme: theme)
    }

    func updateUIView(_ view: ClockPageView, context: Context) {
        view.update(date: date, theme: theme, insets: contentSafeAreaInsets,
                    isScrolling: isScrolling, isVisible: isVisible,
                    isEditingAppearance: isEditingAppearance)
    }

    static func dismantleUIView(_ view: ClockPageView, coordinator: ()) {
        view.stop()
    }
}
