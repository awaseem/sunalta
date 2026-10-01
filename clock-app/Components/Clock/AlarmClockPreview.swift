import SwiftUI
import UIKit

struct AlarmClockPreview: UIViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    let time: String
    let previewHeight: CGFloat
    let contentSafeAreaInsets: UIEdgeInsets

    func makeUIView(context: Context) -> ClockRenderView {
        ClockRenderView(colorScheme: colorScheme, isAlarmPreview: true)
    }

    func updateUIView(_ view: ClockRenderView, context: Context) {
        view.contentSafeAreaInsets = contentSafeAreaInsets
        view.previewHeight = previewHeight
        view.applyAppearance(colorScheme)
        view.showAlarm(time: time)
    }
}
