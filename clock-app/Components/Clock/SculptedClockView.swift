import SwiftUI
import UIKit

struct SculptedClockView: UIViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    let date: Date
    var isScrolling = false
    var isVisible = true
    var lighting = ClockLightingSettings()
    var isEditingLighting = false
    var contentSafeAreaInsets: UIEdgeInsets = .zero

    func makeUIView(context: Context) -> ClockPageView {
        ClockPageView(colorScheme: colorScheme)
    }

    func updateUIView(_ view: ClockPageView, context: Context) {
        view.update(date: date, colorScheme: colorScheme, insets: contentSafeAreaInsets,
                    isScrolling: isScrolling, isVisible: isVisible,
                    lighting: lighting, isEditingLighting: isEditingLighting)
    }

    static func dismantleUIView(_ view: ClockPageView, coordinator: ()) {
        view.stop()
    }
}
