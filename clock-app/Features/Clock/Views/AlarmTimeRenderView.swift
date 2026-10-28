import SwiftUI
import UIKit

struct AlarmTimeRenderView: UIViewRepresentable, Animatable {
    @Environment(\.appTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    let display: ClockTimeDisplay
    var onPeriodAnchorChange: (CGPoint) -> Void
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
        view.isRenderingEnabled = scenePhase == .active
        if scenePhase != .active { view.settleInteraction() }
        view.contentSafeAreaInsets = contentSafeAreaInsets
        view.previewHeight = previewHeight
        view.previewTopInset = previewTopInset
        view.applyTheme(theme)
        view.onPeriodAnchorChange = { anchor in
            Task { @MainActor in onPeriodAnchorChange(anchor) }
        }
        view.show(display: display)
    }

    static func dismantleUIView(_ view: ClockRenderView, coordinator: ()) {
        view.stop()
    }
}
