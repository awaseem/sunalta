import SwiftUI
import UIKit

struct AlarmTimePreview: UIViewRepresentable, Animatable {
    @Environment(\.appTheme) private var theme
    let time: String
    var previewHeight: CGFloat
    var previewTopInset: CGFloat
    let contentSafeAreaInsets: UIEdgeInsets

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(previewHeight, previewTopInset) }
        set {
            previewHeight = newValue.first
            previewTopInset = newValue.second
        }
    }

    func makeUIView(context: Context) -> ClockRenderView {
        ClockRenderView(theme: theme, isAlarmPreview: true)
    }

    func updateUIView(_ view: ClockRenderView, context: Context) {
        view.contentSafeAreaInsets = contentSafeAreaInsets
        view.previewHeight = previewHeight
        view.previewTopInset = previewTopInset
        view.applyTheme(theme)
        view.showAlarm(time: time)
    }

    static func dismantleUIView(_ view: ClockRenderView, coordinator: ()) {
        view.stop()
    }
}
