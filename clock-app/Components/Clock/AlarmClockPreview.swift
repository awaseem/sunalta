import SwiftUI
import UIKit

struct AlarmClockPreview: UIViewRepresentable {
    @Environment(\.appTheme) private var theme
    let time: String
    let previewHeight: CGFloat
    let contentSafeAreaInsets: UIEdgeInsets

    func makeUIView(context: Context) -> ClockRenderView {
        ClockRenderView(theme: theme, isAlarmPreview: true)
    }

    func updateUIView(_ view: ClockRenderView, context: Context) {
        view.contentSafeAreaInsets = contentSafeAreaInsets
        view.previewHeight = previewHeight
        view.applyTheme(theme)
        view.showAlarm(time: time)
    }
}
